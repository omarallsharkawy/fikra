part of 'voice_text_controller.dart';

extension VoiceTextRemote on VoiceTextController {
  Future<void> _runRemote(SpikeRecording clip, TranscriptionService? service) async {
    final before = memoryMb(ProcessInfo.currentRss);
    final clock = Stopwatch()..start();
    final run = <String, Object?>{
      'mode': 'remote',
      'engine_id': service?.engineId,
      'service_name': service?.name,
      'source_format': clip.format,
      'audio_seconds': clip.seconds,
      'language': service?.language ?? language,
      'text': '',
      'error': null,
      'rss_before_mb': before,
    };
    try {
      if (externalEngineFactory == null) throw const TranscriptionFailure(TranscriptionFailureReason.consentRequired);
      final engine = await externalEngineFactory!();
      run['engine_id'] = engine.id;
      run['text'] = await engine.transcribe(clip.path, language: language);
    } catch (error) {
      final reason = error is TranscriptionFailure ? error.reason : TranscriptionFailureReason.unexpectedResponse;
      run['error'] = 'remote'; // Never keep provider error bodies or credentials.
      run['error_kind'] = VoiceTextIssue.remote.name;
      run['failure_reason'] = reason.name;
      throw TranscriptionFailure(reason);
    } finally {
      clock.stop();
      run['wall_ms'] = clock.elapsedMilliseconds;
      run['rtf'] = realTimeFactor(clock.elapsedMilliseconds, clip.seconds);
      run['rss_after_mb'] = memoryMb(ProcessInfo.currentRss);
      run['rss_max_mb'] = memoryMb(ProcessInfo.maxRss);
      // UI-only history. Remote text, keys and audio never enter logcat/JSONL.
      _addRun(run);
    }
  }
}
