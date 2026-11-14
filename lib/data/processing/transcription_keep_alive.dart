/// Keeps the app process running while the transcription queue has work, so
/// the phone does not freeze or kill it after the user leaves the app. On
/// Android this is a foreground service with a notification. Inference itself
/// stays in the app's own Dart isolate; this only keeps the process alive.
abstract interface class TranscriptionKeepAlive {
  /// Starts the keep-alive, or updates it when it already runs. [remaining]
  /// counts the job that is starting and the ones waiting after it.
  Future<void> start(int remaining);

  /// Stops it. Safe to call when it is not running.
  Future<void> stop();
}

/// For platforms without a keep-alive, and for tests.
class NoTranscriptionKeepAlive implements TranscriptionKeepAlive {
  const NoTranscriptionKeepAlive();
  @override
  Future<void> start(int remaining) async {}
  @override
  Future<void> stop() async {}
}
