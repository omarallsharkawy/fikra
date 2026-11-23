import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/processing/transcription_engine.dart';
import '../../data/processing/whisper_lock.dart';
import '../../data/settings_repository.dart';
import 'voice_text_preferences.dart';
import 'whisper_file_engine.dart';
import 'whisper_models.dart';
import 'whisper_recordings.dart';

/// The native adapter lives beside the proven spike engine; the durable queue
/// depends only on TranscriptionEngine. No recorder or model loads at startup.
class LocalTranscriptionEngine implements TranscriptionEngine {
  LocalTranscriptionEngine(this.model, this.models, this.recordings, this.lock);
  final SpikeModel model;
  final SpikeModelStore models;
  final RecordingStore recordings;
  final WhisperLock lock;
  @override
  String get id => 'local:${model.filename}';

  static Future<TranscriptionEngine> prepare(VoiceTextSettings settings, WhisperLock lock) async {
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/fikra_whisper_spike');
    final models = SpikeModelStore(Directory('${root.path}/models'));
    final saved = await settings.readVoiceTextChoices();
    final sizes = <String, int>{};
    for (final m in allSpikeModels) {
      if (await models.file(m).exists()) sizes[m.modelName] = await models.file(m).length();
    }
    final model = saved.modelName == null
        ? preferredVoiceTextModel(sizes)
        : allSpikeModels.where((m) => m.modelName == saved.modelName).firstOrNull;
    if (model == null || (sizes[model.modelName] ?? 0) == 0) {
      throw const TranscriptionFailure(TranscriptionFailureReason.modelMissing);
    }
    return LocalTranscriptionEngine(model, models, RecordingStore(Directory('${root.path}/recordings')), lock);
  }

  @override
  Future<String> transcribe(String audioPath, {required String language}) async {
    final lease = await lock.acquire();
    try {
      try {
        await models.validate(model);
      } catch (_) {
        throw const TranscriptionFailure(TranscriptionFailureReason.modelMissing);
      }
      final audio = File(audioPath);
      if (!await audio.exists() || await audio.length() == 0) {
        throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
      }
      // Note recordings are private: no transcript in logcat or the experiment's run history.
      final result = await WhisperFileEngine(
        models,
        recordings,
        const {},
      ).run(model, SpikeRecording(audioPath, 'aac_lc_m4a_64k_mono', 0), language, 4, private: true);
      if (result['error'] != null) {
        throw TranscriptionFailure(
          result['error_kind'] == 'corrupt'
              ? TranscriptionFailureReason.modelMissing
              : result['error_kind'] == 'empty' || result['conversion_failed'] == true
              ? TranscriptionFailureReason.audioUnreadable
              : TranscriptionFailureReason.other,
        );
      }
      return result['text'] as String;
    } on FileSystemException {
      throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
    } finally {
      lease.release();
    }
  }
}
