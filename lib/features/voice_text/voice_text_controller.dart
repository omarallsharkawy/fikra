import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/widgets/voice_player.dart';
import '../shared/inline_recorder.dart';
import 'voice_text_backend.dart';
import 'whisper_live_engine.dart';

enum VoiceTextPhase { loading, idle, downloading, starting, recording, stopping, transcribing, live }

class VoiceTextController extends ChangeNotifier {
  VoiceTextController(this.backend, {required this.claimMicrophone, required this.releaseMicrophone});
  final VoiceTextBackend backend;
  final bool Function() claimMicrophone;
  final VoidCallback releaseMicrophone;
  static const maxRecording = Duration(minutes: 30);
  SpikeModel model = spikeModels.first;
  String language = 'ar';
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

  void chooseModel(SpikeModel value) {
    if (idle) {
      model = value;
      _notify();
    }
  }

  void chooseLanguage(String value) {
    if (idle) {
      language = value;
      _notify();
    }
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
    final inventory = await backend.load();
    sizes = inventory.sizes;
    clips = inventory.recordings;
    if (model.localOnly && !downloaded) model = spikeModels.first;
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

  Future<void> download() {
    if (!idle || model.localOnly) return Future.value();
    received = 0;
    total = 0;
    progress = null;
    _downloadCancelled = false;
    return _perform(VoiceTextPhase.downloading, () async {
      await backend.checkSpace(model);
      if (_downloadCancelled) throw const VoiceTextFailure(VoiceTextIssue.cancelled);
      final repaintClock = Stopwatch()..start();
      try {
        await backend.download(model, (bytes, length) {
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

  Future<void> deleteModel() => idle
      ? _perform(VoiceTextPhase.stopping, () async {
          await backend.deleteModel(model);
          await _refresh();
        })
      : Future.value();
  Future<void> deleteClip(SpikeRecording clip) => idle
      ? _perform(VoiceTextPhase.stopping, () async {
          await voicePlaybackCoordinator.stop();
          await backend.deleteRecording(clip);
          await _refresh();
        })
      : Future.value();

  void _release() {
    if (_ownsMicrophone) {
      releaseMicrophone();
      _ownsMicrophone = false;
    }
  }

  Future<void> _captureClock() async {
    elapsed = Duration.zero;
    levels.clear();
    _clock
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      elapsed = _clock.elapsed;
      _notify();
      if (elapsed >= maxRecording && capturing) unawaited(stop());
    });
    _amplitude = backend.amplitudeDb.listen(
      (db) {
        levels.add(levelFromDb(db));
        if (levels.length > kWaveformSamples) levels.removeAt(0);
        _notify();
      },
      onError: (Object error) {
        issue = voiceTextIssue(error);
        _notify();
        if (capturing) unawaited(stop());
      },
    );
  }

  Future<void> start({bool live = false}) {
    if (!idle) return Future.value();
    if (!claimMicrophone()) {
      issue = VoiceTextIssue.permission;
      _notify();
      return Future.value();
    }
    _ownsMicrophone = true;
    return _perform(VoiceTextPhase.starting, () async {
      try {
        await voicePlaybackCoordinator.stop();
        if (live) {
          _live = await backend.startLive(model, language, threads);
          partial = '';
          _partials = _live!.partials.listen(
            (text) {
              partial = text;
              _notify();
            },
            onError: (Object error) {
              issue = voiceTextIssue(error);
              _notify();
              if (capturing) unawaited(stop());
            },
          );
        } else {
          await backend.startRecording(aac);
        }
        await _captureClock();
        phase = live ? VoiceTextPhase.live : VoiceTextPhase.recording;
      } catch (_) {
        try {
          await backend.cancelRecording();
        } finally {
          _release();
        }
        rethrow;
      }
    });
  }

  Future<void> _stopClock() async {
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    await _amplitude?.cancel();
    _amplitude = null;
  }

  Future<void> stop({bool discard = false}) {
    if (!capturing) return Future.value();
    final live = phase == VoiceTextPhase.live;
    final previousIssue = issue;
    return _perform(VoiceTextPhase.stopping, () async {
      try {
        await _stopClock();
        if (live) {
          _addRun(await _live!.stop());
          await _partials?.cancel();
          _partials = null;
          _live = null;
        } else if (discard) {
          await backend.cancelRecording();
        } else {
          try {
            await backend.stopRecording();
          } catch (_) {
            await backend.cancelRecording();
            rethrow;
          }
          await _refresh();
          selected = clips.firstOrNull;
        }
        issue ??= previousIssue;
      } finally {
        _release();
      }
    });
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

  Future<void> transcribe() {
    if (!idle || selected == null || !downloaded) return Future.value();
    return _perform(VoiceTextPhase.transcribing, () async {
      await voicePlaybackCoordinator.stop();
      _addRun(await backend.transcribe(model, selected!, language, threads));
    });
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
