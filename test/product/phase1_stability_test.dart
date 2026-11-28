import 'dart:async';
import 'dart:io';

import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/product/api/api_models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/repositories.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/features/capture/local_documents.dart';
import 'package:fikra/features/capture/native_capture_device.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../support/app_harness.dart' show loadAppFonts;
import '../support/recording_fake.dart';
import 'controller_test.dart' show TestCaptureDevice;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class _FlakyCurrentAccountAuth extends DevelopmentAuthRepository {
  bool failMe = true;
  int meCalls = 0;

  @override
  Future<Account> currentAccount(TokenPair tokens) async {
    meCalls++;
    if (failMe) throw const ProductFailure(FailureKind.uncertain, cause: FailureCause.connection);
    return const Account(id: 'development-reader', email: 'reader@example.invalid', emailVerified: true);
  }
}

class _CorruptAttemptStore implements AttemptStore {
  int clearCalls = 0;
  @override
  Future<CreateAttempt?> read(String accountId) async => throw const FormatException('corrupt json');
  @override
  Future<void> write(CreateAttempt attempt) async {}
  @override
  Future<void> clear(String accountId) async {
    clearCalls++;
  }
}

class _FailingClearAttemptStore extends MemoryAttemptStore {
  @override
  Future<void> clear(String accountId) async => throw const ProductFailure(FailureKind.unavailable);
}

class _ConflictSaveRepo extends DevelopmentKnowledgeRepository {
  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async => throw const ProductFailure(FailureKind.conflict);
}

class _CountingNotesRepo extends DevelopmentKnowledgeRepository {
  int notesCalls = 0;
  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) {
    notesCalls++;
    return super.notes(accountId, projectId);
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('Phase 1 critical stability fixes', () {
    test('messageFromJson accepts omitted or null sources', () {
      final omitted = messageFromJson({
        'id': 'm1',
        'role': 'user',
        'content': 'Hello',
        'supported': null,
        'created_at': '2026-11-28T10:00:00Z',
      });
      expect(omitted.sources, isEmpty);

      final explicitNull = messageFromJson({
        'id': 'm2',
        'role': 'assistant',
        'content': 'Hi',
        'supported': true,
        'created_at': '2026-11-28T10:00:00Z',
        'sources': null,
      });
      expect(explicitNull.sources, isEmpty);
    });

    test('offline/transient restore failure preserves vault and retries cleanly', () async {
      final vault = MemorySessionVault();
      final savedPair = TokenPair(access: 'ok-access', refresh: 'ok-refresh', expiresAt: DateTime(2030));
      await vault.replace(savedPair);
      final auth = _FlakyCurrentAccountAuth();
      final session = SessionController(auth, vault);
      addTearDown(session.dispose);

      await session.restore();
      expect(session.stage, SessionStage.restoring);
      expect(session.failure?.kind, FailureKind.uncertain);
      expect(await vault.read(), same(savedPair));

      auth.failMe = false;
      await session.restore();
      expect(session.stage, SessionStage.authenticated);
      expect(session.failure, isNull);
      expect(session.account?.id, 'development-reader');
      expect(auth.meCalls, 2);
    });

    test('inactive lifecycle overlay does not cancel mic start or trigger workspace reload', () async {
      final repo = _CountingNotesRepo();
      final device = TestCaptureDevice()..starting = Completer<void>();
      final runtime = ProductRuntime(
        DevelopmentAuthRepository(),
        MemorySessionVault(),
        repo,
        MemoryAttemptStore(),
        device,
      );
      addTearDown(runtime.dispose);
      await runtime.session.restore();
      await runtime.session.login('other@example.invalid', 'fixture-only');
      await Future<void>.delayed(Duration.zero);
      final initialReads = repo.notesCalls;

      final startFuture = runtime.capture.start();
      await Future<void>.delayed(Duration.zero);
      expect(runtime.capture.state, CaptureState.starting);

      // Simulate transient overlay: calling foreground(true) while already foreground is a no-op.
      runtime.foreground(true);
      expect(runtime.capture.state, CaptureState.starting);
      expect(repo.notesCalls, initialReads);

      device.starting!.complete();
      await startFuture;
      expect(runtime.capture.state, CaptureState.recording);

      // True backgrounding stops recording.
      runtime.foreground(false);
      await Future<void>.delayed(Duration.zero);
      expect(runtime.capture.state, CaptureState.recorded);
    });

    testWidgets('ProductBoundary ignores AppLifecycleState.inactive and backgrounds on paused', (tester) async {
      final repo = _CountingNotesRepo();
      final r = await boot(tester, knowledge: repo, size: const Size(360, 800));
      await r.session.login('other@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
      await r.capture.start();
      await tester.pump();
      expect(r.capture.state, CaptureState.recording);
      final readsBefore = repo.notesCalls;

      // Transient OS overlay (permission dialog / notification shade): inactive -> resumed.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(r.capture.state, CaptureState.recording);
      expect(repo.notesCalls, readsBefore);

      // True backgrounding follows Flutter's lifecycle state machine:
      // resumed -> inactive -> hidden -> paused.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(r.capture.state, CaptureState.recorded);

      // Restore resumed state cleanly: paused -> hidden -> inactive -> resumed.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await cleanup(tester);
    });

    test('pendingAttempt survives reload, unlocks on conflict/deleted project, and hydrates draft on restore', () async {
      // 1. Conflict + reload preserves attemptFailure & allows reviewFailedAttempt.
      final attempts = MemoryAttemptStore();
      final w = WorkspaceController(_ConflictSaveRepo(), attempts);
      addTearDown(w.dispose);
      await w.openAccount('development-other');
      w.updateDraft(title: 'My Title', content: 'Important content');
      await w.save();
      expect(w.pendingAttempt, isNotNull);
      expect(w.attemptFailure?.kind, FailureKind.conflict);
      expect(w.canReviewFailedAttempt, isTrue);

      await w.reload();
      expect(w.failure, isNull);
      expect(w.attemptFailure?.kind, FailureKind.conflict);
      expect(w.canReviewFailedAttempt, isTrue);

      // 2. Restart hydrates draft from persisted attempt & unlocks if attempt project was deleted.
      await attempts.write(
        const CreateAttempt(
          accountId: 'development-other',
          projectId: 'deleted-project-id',
          key: 'k-orphan',
          title: 'Restored title',
          content: 'Restored body',
        ),
      );
      final w2 = WorkspaceController(DevelopmentKnowledgeRepository(), attempts);
      addTearDown(w2.dispose);
      await w2.openAccount('development-other');
      expect(w2.pendingAttempt?.projectId, 'deleted-project-id');
      expect(w2.draft.title, 'Restored title');
      expect(w2.draft.content, 'Restored body');
      expect(w2.canReviewFailedAttempt, isTrue);
      await w2.reviewFailedAttempt();
      expect(w2.pendingAttempt, isNull);
      expect(w2.draft.content, 'Restored body');
    });

    test('local project mismatch on an uncertain save does not unlock reviewFailedAttempt', () async {
      final repo = DevelopmentKnowledgeRepository();
      final attempts = MemoryAttemptStore();
      final w = WorkspaceController(repo, attempts);
      addTearDown(w.dispose);
      await w.openAccount('development-other');
      final generalId = w.selectedProjectId!;
      await w.saveProject('Second');
      final secondId = w.selectedProjectId!;
      await attempts.write(
        CreateAttempt(
          accountId: 'development-other',
          projectId: secondId,
          key: 'uncertain-key',
          content: 'Must reconcile in Second',
        ),
      );
      await w.openAccount('development-other');
      expect(w.selectedProjectId, generalId);
      expect(w.pendingAttempt?.projectId, secondId);
      expect(w.canReviewFailedAttempt, isFalse);

      // Attempting save in wrong project returns local conflict without unlocking discard.
      await w.save();
      expect(w.failure?.kind, FailureKind.conflict);
      expect(w.canReviewFailedAttempt, isFalse);
    });

    test('openNote evicts cached note when server returns notFound', () async {
      final repo = DevelopmentKnowledgeRepository();
      final w = WorkspaceController(repo, MemoryAttemptStore());
      addTearDown(w.dispose);
      await w.openAccount('development-reader');
      final noteId = w.notes.first.id;
      await w.openNote(noteId);
      expect(w.detailFor(noteId), isNotNull);

      await repo.deleteNote('development-reader', noteId);
      await w.openNote(noteId);
      expect(w.detailFor(noteId), isNull);
      expect(w.detailFailureFor(noteId)?.kind, FailureKind.notFound);
      expect(w.notes.any((n) => n.id == noteId), isFalse);
    });

    test('corrupt AttemptStore does not block openAccount and failing clear after save still succeeds', () async {
      final corrupt = _CorruptAttemptStore();
      final w1 = WorkspaceController(DevelopmentKnowledgeRepository(), corrupt);
      addTearDown(w1.dispose);
      await w1.openAccount('development-other');
      expect(w1.selected, isNotNull);
      expect(w1.failure, isNull);
      expect(corrupt.clearCalls, 1);

      final failingClear = _FailingClearAttemptStore();
      final w2 = WorkspaceController(DevelopmentKnowledgeRepository(), failingClear);
      addTearDown(w2.dispose);
      await w2.openAccount('development-other');
      w2.updateDraft(content: 'Saved despite clear error');
      final saved = await w2.save();
      expect(saved, isNotNull);
      expect(w2.pendingAttempt, isNull);
      expect(w2.notes.single.content, 'Saved despite clear error');
    });

    test('session.expire preserves pending attempts while signOut clears them', () async {
      final attempts = MemoryAttemptStore();
      final runtime = ProductRuntime(
        DevelopmentAuthRepository(),
        MemorySessionVault(),
        DevelopmentKnowledgeRepository(),
        attempts,
        TestCaptureDevice(),
      );
      addTearDown(runtime.dispose);
      await runtime.session.restore();
      await runtime.session.login('other@example.invalid', 'fixture-only');
      await Future<void>.delayed(Duration.zero);
      final accountId = runtime.session.account!.id;
      final attempt = CreateAttempt(
        accountId: accountId,
        projectId: 'p1',
        key: 'k1',
        content: 'Do not lose on expiry',
      );
      await attempts.write(attempt);

      await runtime.session.expire();
      await Future<void>.delayed(Duration.zero);
      expect(await attempts.read(accountId), isNotNull);

      await runtime.session.login('other@example.invalid', 'fixture-only');
      await Future<void>.delayed(Duration.zero);
      await runtime.session.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(await attempts.read(accountId), isNull);
    });

    test('NativeCaptureDevice recovers after recorder cancel/stop error and CaptureController.cancel keeps PDFs', () async {
      final previous = RecordPlatform.instance;
      final events = <String>[];
      final fake = RecordingFake(events);
      RecordPlatform.instance = fake;
      final dir = await Directory.systemTemp.createTemp('fikrah-recovery-');
      final device = NativeCaptureDevice(
        null,
        () async => PermissionStatus.granted,
        AttachmentStore(tempDir: () async => dir, documentsDir: () async => dir),
      );
      final capture = CaptureController(device, DevelopmentKnowledgeRepository());
      try {
        capture.setAccount('user-a');
        capture.localPdfs = const [LocalDocument('/doc.pdf', 'doc.pdf')];
        await capture.start();
        expect(capture.state, CaptureState.recording);

        // Simulate both cancel and stop failing on the underlying recorder.
        fake.failCancel = true;
        fake.failStop = true;
        await capture.cancel();
        expect(capture.localPdfs.single.name, 'doc.pdf');

        // Subsequent recording must still succeed with a fresh recorder instance.
        fake.failCancel = false;
        fake.failStop = false;
        await capture.start();
        expect(capture.state, CaptureState.recording);
        await capture.stop();
        expect(capture.state, CaptureState.recorded);
        expect(capture.clip, isNotNull);
      } finally {
        capture.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        RecordPlatform.instance = previous;
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    test('stacked note opens preserve note A detail and target mutations by noteId', () async {
      final w = WorkspaceController(DevelopmentKnowledgeRepository(), MemoryAttemptStore());
      addTearDown(w.dispose);
      await w.openAccount('development-reader');
      expect(w.notes.length, greaterThanOrEqualTo(2));
      final a = w.notes[0], b = w.notes[1];

      await w.openNote(a.id);
      await w.openNote(b.id);
      expect(w.detail?.id, b.id);
      expect(w.detailFor(a.id)?.id, a.id);
      expect(w.detailFor(b.id)?.id, b.id);

      final edited = await w.edit(const NotePatch(content: 'Edited A explicitly'), noteId: a.id);
      expect(edited, isTrue);
      expect(w.detailFor(a.id)?.content, 'Edited A explicitly');
      expect(w.detailFor(b.id)?.content, b.content);
    });

    testWidgets('closing composer stops an active recording so mic never stays live in background', (tester) async {
      final r = await boot(tester, size: const Size(360, 800));
      await r.session.login('other@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
      await r.capture.start();
      await tester.pump();
      expect(r.capture.state, CaptureState.recording);

      await tapVisible(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(r.capture.state, isNot(CaptureState.recording));
      expect(r.capture.state, CaptureState.recorded);
      await cleanup(tester);
    });
  });
}
