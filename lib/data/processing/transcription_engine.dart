/// The queue and presentation know no provider-specific request format.
abstract interface class TranscriptionEngine {
  String get id;
  Future<String> transcribe(String audioPath, {required String language});
}

enum TranscriptionFailureReason {
  modelMissing,
  busy,
  audioUnreadable,

  /// The app closed during this recording's transcription twice in a row.
  interruptedTwice,
  other,
}

class TranscriptionFailure implements Exception {
  const TranscriptionFailure(this.reason);
  final TranscriptionFailureReason reason;
}

/// Resolve credentials/model/settings anew for each job, not when enqueuing.
typedef TranscriptionEngineFactory = Future<TranscriptionEngine> Function();
