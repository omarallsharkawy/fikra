import 'dart:async';

import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/processing/whisper_lock.dart';
import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:fikra/features/voice_text/voice_text_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'voice_text/fake_voice_text_backend.dart';

void main() {
  test('lease waits FIFO, expired waiter removed, double release harmless', () async {
    final lock = WhisperLock();
    final first = lock.tryAcquire()!;
    addTearDown(first.release);
    final expired = lock.acquire(timeout: Duration.zero);
    await expectLater(
      expired,
      throwsA(isA<TranscriptionFailure>().having((e) => e.reason, 'reason', TranscriptionFailureReason.busy)),
    );
    final waiting = lock.acquire();
    expect(lock.tryAcquire(), isNull);
    first.release();
    first.release();
    final next = await waiting;
    expect(lock.busy, isTrue);
    next.release();
    expect(lock.busy, isFalse);
  });

  test('test screen refuses file/live work during queue lease and shares the lock during runs', () async {
    final lock = WhisperLock();
    final backend = FakeVoiceTextBackend()..sizes['tiny-q5_1'] = 100;
    final c = VoiceTextController(
      backend,
      settings: FakeVoiceTextSettings(),
      whisperLock: lock,
      claimMicrophone: () => true,
      releaseMicrophone: () {},
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.start();
    await c.stop();
    final queueLease = await lock.acquire();
    await c.transcribe();
    expect(c.issue, VoiceTextIssue.busy);
    await c.start(live: true);
    expect(c.issue, VoiceTextIssue.busy);
    expect(c.phase, VoiceTextPhase.idle);
    queueLease.release();
    backend.runGate = Completer<Map<String, Object?>>();
    final gate = backend.runGate!;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete(sampleVoiceTextRun());
    });
    final running = c.transcribe();
    expect(lock.tryAcquire(), isNull);
    backend.runGate!.complete(sampleVoiceTextRun());
    await running;
    final lease = lock.tryAcquire();
    expect(lease, isNotNull);
    lease!.release();
    backend.runGate = null;
    await c.start(live: true);
    expect(lock.busy, isTrue);
    final waiting = lock.acquire();
    await c.stop();
    final afterLive = await waiting;
    afterLive.release();
    expect(lock.busy, isFalse);
  });
}
