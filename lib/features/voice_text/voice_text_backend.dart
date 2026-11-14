import 'dart:async';
import 'dart:io';

import 'whisper_models.dart';
import 'whisper_recordings.dart';

export 'whisper_models.dart';
export 'whisper_recordings.dart' show SpikeRecording;

enum VoiceTextIssue {
  network,
  interrupted,
  corrupt,
  permission,
  empty,
  transcription,
  storage,
  storageCheck,
  cancelled,
  unknown,
}

class VoiceTextFailure implements Exception {
  const VoiceTextFailure(this.issue);
  final VoiceTextIssue issue;
}

VoiceTextIssue voiceTextIssue(Object error) {
  if (error is VoiceTextFailure) return error.issue;
  if (error is SocketException || error is HttpException) return VoiceTextIssue.network;
  if (error is TimeoutException) return VoiceTextIssue.interrupted;
  if (error is FileSystemException && error.osError?.errorCode == 28) return VoiceTextIssue.storage;
  final message = error.toString().toLowerCase();
  if (message.contains('cancelled')) return VoiceTextIssue.cancelled;
  if (message.contains('download interrupted')) return VoiceTextIssue.interrupted;
  if (message.contains('model') || message.contains('corrupt')) return VoiceTextIssue.corrupt;
  if (message.contains('empty') || message.contains('wav')) return VoiceTextIssue.empty;
  return VoiceTextIssue.unknown;
}

class VoiceTextInventory {
  const VoiceTextInventory({this.sizes = const {}, this.recordings = const [], this.warning});
  final Map<String, int> sizes;
  final List<SpikeRecording> recordings;
  final VoiceTextIssue? warning;
}

/// All native/file/network boundaries are replaceable in widget tests.
abstract interface class VoiceTextBackend {
  Future<VoiceTextInventory> load();
  Future<void> checkSpace(SpikeModel model);
  Future<void> download(SpikeModel model, void Function(int received, int total) progress);
  void cancelDownload();
  Future<void> deleteModel(SpikeModel model);
  Future<void> deleteRecording(SpikeRecording clip);
  Stream<double> get amplitudeDb;
  Future<void> startRecording(bool aac);
  Future<void> stopRecording();
  Future<void> cancelRecording();
  Future<Map<String, Object?>> transcribe(SpikeModel model, SpikeRecording clip, String language, int threads);
  Future<VoiceTextLive> startLive(SpikeModel model, String language, int threads);
  Future<void> dispose();
}

abstract interface class VoiceTextLive {
  Stream<String> get partials;
  Future<Map<String, Object?>> stop();
}
