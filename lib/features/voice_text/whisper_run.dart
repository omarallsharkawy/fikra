import 'dart:io';

import 'whisper_metrics.dart';
import 'whisper_models.dart';
import 'whisper_recordings.dart';

/// Retains the standalone spike's JSON schema and exact prefix.
class WhisperRun {
  WhisperRun(
    SpikeModel model,
    String language,
    int threads,
    String format,
    double seconds,
    String mode,
    Map<String, Object?> ffmpeg,
  ) : values = {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'mode': mode,
        'model': model.filename,
        'model_url': model.localOnly ? null : modelUrl(model),
        'language': language,
        'threads': threads,
        'source_format': format,
        'ffmpeg': Map<String, Object?>.of(ffmpeg),
        'audio_seconds': seconds,
        'audio_duration_source': format.startsWith('aac') ? 'recording_clock_estimate' : 'pcm_samples',
        'wall_ms': 0,
        'rtf': null,
        'conversion_ms': null,
        'transcription_wall_ms_estimate': null,
        'model_load_ms': null,
        'rss_before_mb': memoryMb(ProcessInfo.currentRss),
        'max_rss_before_mb': memoryMb(ProcessInfo.maxRss),
        'text': '',
        'error': null,
      };

  final Map<String, Object?> values;
  final wall = Stopwatch();

  /// A [private] run (a saved note's recording) logs its numbers without the
  /// spoken text and is not added to the experiment's run history file.
  Future<Map<String, Object?>> finish(RecordingStore recordings, {bool private = false}) async {
    wall.stop();
    values.addAll({
      'wall_ms': wall.elapsedMilliseconds,
      'rtf': realTimeFactor(wall.elapsedMilliseconds, (values['audio_seconds'] as num).toDouble()),
      'rss_after_mb': memoryMb(ProcessInfo.currentRss),
      'rss_max_mb': memoryMb(ProcessInfo.maxRss),
    });
    if (private) {
      final text = values['text'] as String? ?? '';
      // ignore: avoid_print
      print(
        whisperLogLine({
          ...values,
          'text': null,
          'text_chars': text.length,
          'error': values['error'] == null ? null : 'transcription_failed',
        }),
      );
      return Map.unmodifiable(values);
    }
    final safe = {
      ...values,
      'text': null,
      'text_chars': (values['text'] as String? ?? '').length,
      'error': values['error'] == null ? null : 'transcription_failed',
    };
    var line = whisperLogLine(safe);
    try {
      await recordings.appendRun(line);
    } catch (_) {
      values['history_storage_error'] = 'storage_failed';
      line = whisperLogLine({...safe, 'history_storage_error': 'storage_failed'});
    }
    // One unthrottled JSON line per attempted run, including failures.
    // ignore: avoid_print
    print(line);
    return Map.unmodifiable(values);
  }
}
