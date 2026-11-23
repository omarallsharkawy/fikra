import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';

class LimitedAuth extends DevelopmentAuthRepository {
  int calls = 0;
  @override
  Future<SessionGrant> login(String email, String password) async {
    calls++;
    throw const ProductFailure(FailureKind.quota, retryAfter: Duration(seconds: 5));
  }
}

class LimitedTranscription extends DevelopmentKnowledgeRepository {
  LimitedTranscription({this.kind = FailureKind.quota});
  final FailureKind kind;
  int calls = 0;
  @override
  Future<String> transcribe(String accountId, RecordedClip recording) async {
    calls++;
    throw ProductFailure(kind, retryAfter: kind == FailureKind.quota ? const Duration(seconds: 5) : null);
  }
}

class ReadyRecorder implements CaptureDevice {
  @override
  Future<void> start() async {}
  @override
  Future<RecordedClip?> stop(Duration duration) async => RecordedClip('/fixture.m4a', 'audio/m4a', duration);
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test('account actions honor Retry-After without discarding input or replaying', () async {
    var now = DateTime.utc(2026);
    final repo = LimitedAuth();
    final session = SessionController(repo, MemorySessionVault(), clock: () => now);
    addTearDown(session.dispose);
    await session.restore();
    await session.login('reader@example.invalid', 'fixture-only');
    expect(session.coolingDown, isTrue);
    expect(session.email, 'reader@example.invalid');
    await session.login('reader@example.invalid', 'fixture-only');
    expect(repo.calls, 1);
    now = now.add(const Duration(seconds: 6));
    await session.login('reader@example.invalid', 'fixture-only');
    expect(repo.calls, 2);
    await session.signOut();
    expect(session.coolingDown, isFalse);
  });
  test('transcription quota preserves the recording and blocks early retries', () async {
    var now = DateTime.utc(2026);
    final repo = LimitedTranscription();
    final capture = CaptureController(ReadyRecorder(), repo, clock: () => now);
    addTearDown(capture.dispose);
    capture.setAccount('development-other');
    await capture.start();
    await capture.stop();
    final recording = capture.clip;
    await capture.transcribe();
    expect(capture.coolingDown, isTrue);
    expect(capture.clip, same(recording));
    await capture.transcribe();
    expect(repo.calls, 1);
    expect(capture.transcript, isEmpty);
    await capture.cancel();
    await capture.start();
    await capture.stop();
    await capture.transcribe();
    expect(repo.calls, 1);
    now = now.add(const Duration(seconds: 6));
    await capture.transcribe();
    expect(repo.calls, 2);
    capture.setAccount(null);
    expect(capture.coolingDown, isFalse);
    expect(capture.clip, isNull);
  });
  test('a transcription authorization failure enters the shared session-expiry path', () async {
    var expired = false;
    final repo = LimitedTranscription(kind: FailureKind.unauthorized);
    final capture = CaptureController(ReadyRecorder(), repo, onUnauthorized: () => expired = true);
    addTearDown(capture.dispose);
    capture.setAccount('development-other');
    await capture.start();
    await capture.stop();
    await capture.transcribe();
    expect(expired, isTrue);
    expect(capture.transcript, isEmpty);
    expect(capture.failure!.kind, FailureKind.unauthorized);
  });
}
