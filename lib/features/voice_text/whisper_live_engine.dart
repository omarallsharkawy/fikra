import 'dart:async';

import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'voice_text_backend.dart';
import 'whisper_recordings.dart';
import 'whisper_run.dart';

class VoiceTextRunFailure extends VoiceTextFailure {
  const VoiceTextRunFailure(super.issue, this.run);
  final Map<String, Object?> run;
}

class WhisperMicrophoneLive implements VoiceTextLive {
  WhisperMicrophoneLive(this.recorder, this.recordings, this.run);
  final AudioRecorder recorder;
  final RecordingStore recordings;
  final WhisperRun run;
  final _partials = StreamController<String>();
  WhisperLiveSession? _session;
  StreamSubscription<dynamic>? _audio;
  StreamSubscription<String>? _texts;
  Future<Map<String, Object?>>? _stopping;
  Object? _error;
  int _bytes = 0;

  @override
  Stream<String> get partials => _partials.stream;

  void _failed(Object error) {
    _error = error;
    if (!_partials.isClosed) _partials.addError(error);
  }

  Future<void> start(String modelPath, String language, int threads) async {
    final load = Stopwatch()..start();
    _session = await startWhisperLiveSession(modelPath: modelPath, lang: language, threads: threads);
    load.stop();
    run.values['model_load_ms'] = load.elapsedMilliseconds;
    run.values['model_load_note'] = 'Live startup includes isolate + native context initialization';
    _texts = _session!.partials.listen(_partials.add, onError: _failed);
    final stream = await recorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
    );
    _audio = stream.listen(
      (bytes) {
        _bytes += bytes.length;
        _session!.feed(bytes);
      },
      onError: _failed,
      onDone: () {
        if (_stopping == null) _failed(const VoiceTextFailure(VoiceTextIssue.interrupted));
      },
    );
  }

  Future<Map<String, Object?>> fail(Object error) {
    _error = error;
    return stop();
  }

  @override
  Future<Map<String, Object?>> stop() => _stopping ??= _finish();

  Future<Map<String, Object?>> _finish() async {
    final finalize = Stopwatch()..start();
    try {
      await recorder.stop();
    } catch (e) {
      _error ??= e;
    }
    try {
      await _audio?.cancel();
      run.values['text'] = await _session?.stop() ?? '';
      await _texts?.cancel();
    } catch (e) {
      _error ??= e;
    }
    finalize.stop();
    run.values['audio_seconds'] = _bytes / 32000;
    run.values['finalization_ms'] = finalize.elapsedMilliseconds;
    _error ??= _bytes == 0 ? const VoiceTextFailure(VoiceTextIssue.empty) : null;
    if (_error != null) {
      run.values['error'] = _error.toString();
      final issue = voiceTextIssue(_error!);
      run.values['error_kind'] = (issue == VoiceTextIssue.unknown ? VoiceTextIssue.transcription : issue).name;
    }
    // close() must not wait for an unlistened stream after failed startup.
    unawaited(_partials.close());
    return run.finish(recordings);
  }
}
