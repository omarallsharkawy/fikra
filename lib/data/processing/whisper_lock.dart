import 'dart:async';
import 'dart:collection';

import 'transcription_engine.dart';

/// A process-wide lease: inference cannot be cancelled, so it must retain the
/// lease until native work really ends (never release on a Future.timeout).
class WhisperLock {
  bool _held = false;
  final _waiting = Queue<Completer<WhisperLease>>();
  bool get busy => _held || _waiting.isNotEmpty;

  WhisperLease? tryAcquire() {
    if (busy) return null;
    _held = true;
    return WhisperLease._(this);
  }

  Future<WhisperLease> acquire({Duration timeout = const Duration(minutes: 10)}) async {
    final immediate = tryAcquire();
    if (immediate != null) return immediate;
    final waiter = Completer<WhisperLease>();
    _waiting.add(waiter);
    final timer = Timer(timeout, () {
      if (_waiting.remove(waiter)) {
        waiter.completeError(const TranscriptionFailure(TranscriptionFailureReason.busy));
      }
    });
    try {
      return await waiter.future;
    } finally {
      timer.cancel();
    }
  }

  void _release() {
    if (_waiting.isEmpty) {
      _held = false;
    } else {
      _waiting.removeFirst().complete(WhisperLease._(this));
    }
  }
}

class WhisperLease {
  WhisperLease._(this._lock);
  WhisperLock? _lock;
  void release() {
    _lock?._release();
    _lock = null;
  }
}

/// Also used by native feature backends created outside a ProviderScope.
final appWhisperLock = WhisperLock();
