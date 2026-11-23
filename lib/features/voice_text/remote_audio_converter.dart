import 'dart:io';

// Already supplied by whisper_ggml; same FFmpeg PCM path as file inference.
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/ids.dart';
import '../../data/processing/transcription_engine.dart';
import '../../data/transcription/remote_engine.dart';
import '../../data/transcription/remote_request.dart';

Future<ConvertedUpload> convertRemoteAudio(AudioUpload original) async {
  final temp = await getTemporaryDirectory();
  final file = File('${temp.path}/transcription_${newId()}.wav');
  try {
    final session = await FFmpegKit.executeWithArguments([
      '-loglevel',
      'quiet',
      '-y',
      '-i',
      original.path!,
      '-vn',
      '-ar',
      '16000',
      '-ac',
      '1',
      '-c:a',
      'pcm_s16le',
      file.path,
    ]);
    if ((await session.getReturnCode())?.getValue() != 0) {
      throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
    }
    return ConvertedUpload(await AudioUpload.open(file.path), () async {
      if (await file.exists()) await file.delete();
    });
  } catch (_) {
    if (await file.exists()) await file.delete();
    throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
  }
}
