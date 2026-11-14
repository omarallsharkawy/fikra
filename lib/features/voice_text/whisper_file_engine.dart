import 'dart:io';

// Already supplied by whisper_ggml; no dependency added.
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'voice_text_backend.dart';
import 'whisper_recordings.dart';
import 'whisper_run.dart';

class WhisperFileEngine {
  const WhisperFileEngine(this.models, this.recordings, this.ffmpeg);
  final SpikeModelStore models;
  final RecordingStore recordings;
  final Map<String, Object?> ffmpeg;

  Future<Map<String, Object?>> run(SpikeModel model, SpikeRecording clip, String language, int threads) async {
    final run = WhisperRun(model, language, threads, clip.format, clip.seconds, 'file', ffmpeg);
    final data = run.values;
    int? previousSession;
    try {
      await models.validate(model);
      data['model_bytes'] = await models.file(model).length();
      if (clip.format.startsWith('wav')) data['audio_seconds'] = await wavSeconds(File(clip.path));
      previousSession = (await FFmpegKitConfig.getLastSession())?.getSessionId();
      run.wall.start();
      final result = await Whisper(model: WhisperModel.tiny).transcribe(
        modelPath: models.file(model).path,
        transcribeRequest: TranscribeRequest(
          audio: clip.path,
          language: language,
          threads: threads,
          isNoTimestamps: true,
          keepModelLoaded: false,
        ),
      );
      data['text'] = result.text;
    } catch (e) {
      data['error'] = e.toString();
      final issue = voiceTextIssue(e);
      data['error_kind'] = (issue == VoiceTextIssue.unknown ? VoiceTextIssue.transcription : issue).name;
    } finally {
      run.wall.stop();
      try {
        final session = await FFmpegKitConfig.getLastSession();
        if (run.wall.elapsedMicroseconds > 0 &&
            session != null &&
            session.getSessionId() != previousSession &&
            (session.getArguments()?.contains(clip.path) ?? false)) {
          final conversionMs = await session.getDuration();
          data['conversion_ms'] = conversionMs;
          // FFmpeg session duration excludes Dart/platform setup. Preserve the
          // original spike's explicitly approximate transcription+load figure.
          data['transcription_wall_ms_estimate'] = (run.wall.elapsedMilliseconds - conversionMs).clamp(0, 1 << 62);
          if ((await session.getReturnCode())?.getValue() != 0) {
            data['error'] = '${data['error'] ?? ''} FFmpeg conversion failed';
            data['error_kind'] = VoiceTextIssue.transcription.name;
          } else {
            data['audio_seconds'] = await wavSeconds(File('${clip.path}.wav'));
            data['audio_duration_source'] = 'converted_wav_header';
          }
        }
      } catch (e) {
        data['timing_error'] = e.toString();
        if (e is FormatException) {
          data['error'] = e.toString();
          data['error_kind'] = VoiceTextIssue.empty.name;
        }
      }
      try {
        final converted = File('${clip.path}.wav');
        if (await converted.exists()) await converted.delete();
      } catch (e) {
        data['cleanup_error'] = e.toString();
      }
    }
    return run.finish(recordings);
  }
}
