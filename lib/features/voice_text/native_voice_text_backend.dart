import 'dart:async';
import 'dart:io';

// Transitive dependency already supplied by whisper_ggml.
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_text_backend.dart';
import 'whisper_file_engine.dart';
import 'whisper_live_engine.dart';
import 'whisper_recordings.dart';
import 'whisper_run.dart';

class NativeVoiceTextBackend implements VoiceTextBackend {
  final _recorder = AudioRecorder();
  final _clock = Stopwatch();
  final _ffmpeg = <String, Object?>{};
  late SpikeModelStore _models;
  late RecordingStore _recordings;
  List<SpikeRecording> _clips = [];
  Future<void>? _ready;
  VoiceTextIssue? _warning;
  String? _activePath;
  bool _aac = false;
  bool _storageReady = false;
  WhisperMicrophoneLive? _live;

  Future<void> _initialize() async {
    final support = await getApplicationSupportDirectory();
    // Preserve the standalone spike's files on this branch.
    final root = Directory('${support.path}/fikra_whisper_spike');
    await root.create(recursive: true);
    _models = SpikeModelStore(Directory('${root.path}/models').absolute);
    await _models.directory.create(recursive: true);
    // Once per screen/backend initialization, independently of inference logs.
    // ignore: avoid_print
    print('FIKRA_WHISPER_DIR ${_models.directory.path}');
    _recordings = RecordingStore(Directory('${root.path}/recordings'));
    _storageReady = true;
    if ((await _models.clearInterruptedDownloads()).isNotEmpty) _warning = VoiceTextIssue.interrupted;
    _clips = await _recordings.load();
  }

  bool _probed = false;
  Future<void> _probeFfmpeg() async {
    if (_probed) return;
    _probed = true;
    try {
      _ffmpeg['ffmpeg_version'] = await FFmpegKitConfig.getFFmpegVersion();
      final decoders = await FFmpegKit.execute('-hide_banner -decoders');
      final demuxers = await FFmpegKit.execute('-hide_banner -demuxers');
      _ffmpeg['aac_decoder'] = RegExp(r'^\s*A\S*\s+aac\s', multiLine: true).hasMatch(await decoders.getOutput() ?? '');
      _ffmpeg['m4a_demuxer'] = RegExp(
        r'^\s*D\S*\s+\S*mov,mp4,m4a',
        multiLine: true,
      ).hasMatch(await demuxers.getOutput() ?? '');
    } catch (e) {
      // Does not disable live/WAV testing; keep probe failures in every log.
      _ffmpeg['probe_error'] = e.toString();
      _warning ??= VoiceTextIssue.transcription;
    }
  }

  @override
  Future<VoiceTextInventory> load() async {
    await (_ready ??= _initialize());
    final sizes = <String, int>{};
    for (final model in spikeModels) {
      final file = _models.file(model);
      sizes[model.modelName] = await file.exists() ? await file.length() : 0;
    }
    try {
      final localBytes = await _models.validatedEgyptianBytes();
      if (localBytes != null) sizes[egyptianModel.modelName] = localBytes;
    } on FormatException {
      // A malformed local file stays hidden; use the existing visible error.
      _warning ??= VoiceTextIssue.corrupt;
    }
    final warning = _warning;
    _warning = null;
    return VoiceTextInventory(sizes: sizes, recordings: List.of(_clips), warning: warning);
  }

  @override
  Future<void> checkSpace(SpikeModel model) async {
    try {
      final free = await const MethodChannel('fikra/voice_text_storage').invokeMethod<int>('availableBytes');
      if (free == null) throw const VoiceTextFailure(VoiceTextIssue.storageCheck);
      if (free < model.requiredFreeBytes) throw const VoiceTextFailure(VoiceTextIssue.storage);
    } on VoiceTextFailure {
      rethrow;
    } catch (_) {
      throw const VoiceTextFailure(VoiceTextIssue.storageCheck);
    }
  }

  @override
  Future<void> download(SpikeModel model, void Function(int, int) progress) => _models.download(model, progress);
  @override
  void cancelDownload() => _models.cancelDownload();
  @override
  Future<void> deleteModel(SpikeModel model) => _models.delete(model);
  @override
  Future<void> deleteRecording(SpikeRecording clip) async {
    _clips = await _recordings.remove(clip, _clips);
  }

  @override
  Stream<double> get amplitudeDb =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).map((a) => a.current);

  Future<void> _permission() async {
    if (!await _recorder.hasPermission()) throw const VoiceTextFailure(VoiceTextIssue.permission);
  }

  @override
  Future<void> startRecording(bool aac) async {
    await _permission();
    _aac = aac;
    _activePath = await _recordings.newPath(aac ? 'm4a' : 'wav');
    await _recorder.start(
      aac
          ? const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000)
          : const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: _activePath!,
    );
    _clock
      ..reset()
      ..start();
  }

  @override
  Future<void> stopRecording() async {
    _clock.stop();
    final path = await _recorder.stop();
    if (path == null || _clock.elapsedMilliseconds < 250 || await File(path).length() == 0) {
      throw const VoiceTextFailure(VoiceTextIssue.empty);
    }
    final seconds = _aac ? _clock.elapsedMilliseconds / 1000 : await wavSeconds(File(path));
    final clip = SpikeRecording(path, _aac ? 'aac_lc_m4a_64k_mono' : 'wav_pcm16_16khz_mono', seconds);
    _clips = await _recordings.add(clip, _clips);
    _activePath = null;
  }

  @override
  Future<void> cancelRecording() async {
    await _recorder.cancel();
    final path = _activePath;
    if (path != null && await File(path).exists()) await File(path).delete();
    _activePath = null;
  }

  @override
  Future<Map<String, Object?>> transcribe(SpikeModel model, SpikeRecording clip, String language, int threads) async {
    await _probeFfmpeg();
    return WhisperFileEngine(_models, _recordings, _ffmpeg).run(model, clip, language, threads);
  }

  @override
  Future<VoiceTextLive> startLive(SpikeModel model, String language, int threads) async {
    await _probeFfmpeg();
    final run = WhisperRun(model, language, threads, 'live_pcm16_16khz_mono', 0, 'live', _ffmpeg);
    final live = _live = WhisperMicrophoneLive(_recorder, _recordings, run);
    run.wall.start();
    try {
      await _models.validate(model);
      run.values['model_bytes'] = await _models.file(model).length();
      await _permission();
      await live.start(_models.file(model).path, language, threads);
      return live;
    } catch (e) {
      final result = await live.fail(e);
      throw VoiceTextRunFailure(voiceTextIssue(e), result);
    }
  }

  @override
  Future<void> dispose() async {
    if (_storageReady) _models.cancelDownload();
    try {
      await _live?.stop();
      if (_activePath != null) await cancelRecording();
    } finally {
      await _recorder.dispose();
    }
  }
}
