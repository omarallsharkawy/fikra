import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/widgets/voice_player.dart';
import '../../data/settings_repository.dart';
import '../../data/processing/whisper_lock.dart';
import '../shared/inline_recorder.dart';
import 'voice_text_backend.dart';
import 'whisper_live_engine.dart';
import 'voice_text_preferences.dart';

part 'voice_text_capture.dart';

enum VoiceTextPhase { loading, idle, downloading, starting, recording, stopping, transcribing, live }

class VoiceTextController extends ChangeNotifier {
  VoiceTextController(
    this.backend, {
    required VoiceTextSettings settings,
    required this.claimMicrophone,
    required this.releaseMicrophone,
    WhisperLock? whisperLock,
  }) : choices = VoiceTextPreferences(settings),
       whisperLock = whisperLock ?? appWhisperLock;
  final VoiceTextPreferences choices;
  final WhisperLock whisperLock;
  WhisperLease? _liveLease;
  bool autoTranscribe = false;
  final VoiceTextBackend backend;
  final bool Function() claimMicrophone;
  final VoidCallback releaseMicrophone;
  static const maxRecording = Duration(minutes: 30);
  SpikeModel get model => choices.model;
  String get language => choices.language;
  SpikeModel? downloadingModel;
  int threads = 4;
  bool aac = false;
  VoiceTextPhase phase = VoiceTextPhase.loading;
  VoiceTextIssue? issue;
  Map<String, int> sizes = {};
  List<SpikeRecording> clips = [];
  SpikeRecording? selected;
  final history = <Map<String, Object?>>[];
  final levels = <double>[];
  String partial = '';
  Duration elapsed = Duration.zero;
  double? progress;
  int received = 0;
  int total = 0;
  bool _disposed = false;
  bool _ownsMicrophone = false;
  bool _downloadCancelled = false;
  VoiceTextLive? _live;
  Timer? _ticker;
  StreamSubscription<double>? _amplitude;
  StreamSubscription<String>? _partials;
  Future<void> _pending = Future.value();
  final _clock = Stopwatch();

  bool get idle => phase == VoiceTextPhase.idle;
  List<SpikeModel> get models => [
    spikeModels.first,
    if ((sizes[egyptianModel.modelName] ?? 0) > 0) egyptianModel,
    ...spikeModels.skip(1),
  ];
  bool get downloaded => (sizes[model.modelName] ?? 0) > 0;
  bool get capturing => phase == VoiceTextPhase.recording || phase == VoiceTextPhase.live;
  bool get locked => !idle && phase != VoiceTextPhase.downloading;
  int get usedBytes => sizes.values.fold(0, (a, b) => a + b);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> chooseModel(SpikeModel value) =>
      idle ? _perform(VoiceTextPhase.stopping, () => choices.chooseModel(value)) : Future.value();

  Future<void> chooseLanguage(String value) =>
      idle ? _perform(VoiceTextPhase.stopping, () => choices.chooseLanguage(value)) : Future.value();

  Future<void> setAutoTranscribe(bool enabled) => idle
      ? _perform(VoiceTextPhase.stopping, () async {
          await choices.settings.setAutoTranscribe(enabled);
          autoTranscribe = enabled;
        })
      : Future.value();

  WhisperLease? _claimWhisper() {
    final lease = whisperLock.tryAcquire();
    if (lease == null) {
      issue = VoiceTextIssue.busy;
      _notify();
    }
    return lease;
  }

  void chooseThreads(int value) {
    if (idle) {
      threads = value;
      _notify();
    }
  }

  void chooseFormat(bool value) {
    if (idle) {
      aac = value;
      _notify();
    }
  }

  void chooseClip(SpikeRecording clip) {
    if (idle) {
      selected = clip;
      _notify();
    }
  }

  Future<void> _refresh() async {
    autoTranscribe = await choices.settings.readAutoTranscribe();
    final wasInstalled = downloaded;
    final inventory = await backend.load();
    sizes = inventory.sizes;
    clips = inventory.recordings;
    if (!choices.loaded) {
      await choices.restore(sizes);
    } else if (wasInstalled && !downloaded) {
      await choices.recoverMissing(sizes);
    }
    selected = clips.where((c) => c.path == selected?.path).firstOrNull ?? clips.firstOrNull;
    issue ??= inventory.warning;
  }

  Future<void> _perform(VoiceTextPhase next, Future<void> Function() action) {
    phase = next;
    issue = null;
    _notify();
    return _pending = () async {
      try {
        await action();
      } catch (e) {
        if (e is VoiceTextRunFailure) _addRun(e.run);
        issue = voiceTextIssue(e);
      } finally {
        if (phase != VoiceTextPhase.recording && phase != VoiceTextPhase.live) phase = VoiceTextPhase.idle;
        _notify();
      }
    }();
  }

  Future<void> initialize() => _perform(VoiceTextPhase.loading, _refresh);

  Future<void> download([SpikeModel? requested]) {
    final target = requested ?? model;
    if (!idle || target.localOnly) return Future.value();
    received = 0;
    total = 0;
    progress = null;
    _downloadCancelled = false;
    downloadingModel = target;
    return _perform(VoiceTextPhase.downloading, () async {
      await choices.chooseModel(target);
      await backend.checkSpace(target);
      if (_downloadCancelled) throw const VoiceTextFailure(VoiceTextIssue.cancelled);
      final repaintClock = Stopwatch()..start();
      try {
        await backend.download(target, (bytes, length) {
          received = bytes;
          total = length;
          progress = length > 0 ? (bytes / length).clamp(0, 1) : null;
          if (bytes == 0 || bytes == length || repaintClock.elapsedMilliseconds >= 120) {
            repaintClock.reset();
            _notify();
          }
        });
      } finally {
        await _refresh();
      }
    });
  }

  void cancelDownload() {
    _downloadCancelled = true;
    backend.cancelDownload();
  }

  Future<void> deleteModel([SpikeModel? target]) async {
    if (!idle) return;
    final lease = _claimWhisper();
    if (lease == null) return;
    try {
      await _perform(VoiceTextPhase.stopping, () async {
        await backend.deleteModel(target ?? model);
        await _refresh();
      });
    } finally {
      lease.release();
    }
  }

  Future<void> deleteClip(SpikeRecording clip) => idle
      ? _perform(VoiceTextPhase.stopping, () async {
          await voicePlaybackCoordinator.stop();
          await backend.deleteRecording(clip);
          await _refresh();
        })
      : Future.value();

  void _release() {
    _liveLease?.release();
    _liveLease = null;
    if (_ownsMicrophone) {
      releaseMicrophone();
      _ownsMicrophone = false;
    }
  }

  void _addRun(Map<String, Object?> run) {
    history.insert(0, run);
    if (history.length > 5) history.removeLast();
    if (run['error'] != null) {
      issue =
          VoiceTextIssue.values.where((i) => i.name == run['error_kind']).firstOrNull ?? VoiceTextIssue.transcription;
    } else if (run['history_storage_error'] != null || run['cleanup_error'] != null) {
      issue = VoiceTextIssue.storage;
    }
  }

  Future<void> transcribe() async {
    if (!idle || selected == null || !downloaded) return;
    final lease = _claimWhisper();
    if (lease == null) return;
    try {
      await _perform(VoiceTextPhase.transcribing, () async {
        await voicePlaybackCoordinator.stop();
        _addRun(await backend.transcribe(model, selected!, language, threads));
      });
    } finally {
      lease.release();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    if (phase == VoiceTextPhase.downloading) cancelDownload();
    unawaited(() async {
      try {
        await _pending;
        await _amplitude?.cancel();
        await _partials?.cancel();
        await backend.dispose();
      } catch (e) {
        // Disposal has no mounted UI; preserve evidence instead of swallowing it.
        debugPrint('Voice to text cleanup failed: $e');
      } finally {
        _release();
      }
    }());
    super.dispose();
  }
}
