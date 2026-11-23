import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:fikra/features/conversation/conversation_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/app/product_runtime.dart';

class TestCaptureDevice implements CaptureDevice {
  int starts = 0, stops = 0, cancels = 0;
  Completer<void>? starting;
  Object? startError;
  @override
  Future<void> start() async {
    starts++;
    if (startError != null) throw startError!;
    await starting?.future;
  }

  @override
  Future<RecordedClip?> stop(Duration duration) async {
    stops++;
    return RecordedClip('/fixture.m4a', 'audio/m4a', duration);
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {}
}

class RotatingAuth extends DevelopmentAuthRepository {
  final refreshResult = Completer<TokenPair>();
  int refreshCalls = 0;
  @override
  Future<SessionGrant> login(String email, String password) async => SessionGrant(
    Account(id: email, email: email, emailVerified: true),
    tokens: TokenPair(access: 'old-access', refresh: 'old-refresh', expiresAt: DateTime(2030)),
  );
  @override
  Future<TokenPair> refresh(TokenPair current) {
    refreshCalls++;
    return refreshResult.future;
  }
}

class UncertainCreate extends DevelopmentKnowledgeRepository {
  final sent = <CreateAttempt>[];
  bool throwAfterCommit = true;
  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async {
    sent.add(attempt);
    final result = await super.createNote(attempt);
    if (throwAfterCommit) {
      throwAfterCommit = false;
      throw const ProductFailure(FailureKind.uncertain);
    }
    return result;
  }
}

class DelayedSearch extends DevelopmentKnowledgeRepository {
  final result = Completer<List<NoteSearchResult>>();
  @override
  Future<List<NoteSearchResult>> search(String accountId, String projectId, String query) => result.future;
}

class StaleProposal extends DevelopmentKnowledgeRepository {
  int actions = 0;
  @override
  Future<KnowledgeNote> refine(String a, String id, int generation, RefinementAction action) async {
    actions++;
    await super.refine(a, id, generation, RefinementAction.regenerate);
    throw const ProductFailure(FailureKind.conflict);
  }
}

class ScriptedChat extends DevelopmentKnowledgeRepository {
  ScriptedChat(this.events);
  final List<ChatEvent> Function(Conversation conversation) events;
  int sends = 0, histories = 0;
  @override
  Stream<ChatEvent> send(String a, String id, String text) async* {
    sends++;
    final h = await super.history(a, id);
    yield* Stream.fromIterable(events(h.conversation));
  }

  @override
  Future<ConversationHistory> history(String a, String id) {
    histories++;
    return super.history(a, id);
  }
}

KnowledgeMessage message(String id, String content, bool? supported, {String role = 'assistant'}) =>
    KnowledgeMessage(id: id, role: role, content: content, supported: supported, createdAt: DateTime.utc(2026));

void main() {
  group('account state and session safety', () {
    test('registration and verification never authenticate', () async {
      final c = SessionController(DevelopmentAuthRepository(), MemorySessionVault());
      addTearDown(c.dispose);
      await c.restore();
      expect(c.stage, SessionStage.unauthenticated);
      await c.register(' USER@example.invalid ', 'fixture-only');
      expect(c.stage, SessionStage.awaitingVerification);
      expect(c.account, isNull);
      expect(c.tokens, isNull);
      await c.resend();
      expect(c.stage, SessionStage.awaitingVerification);
      await c.verify('bad');
      expect(c.stage, SessionStage.awaitingVerification);
      expect(c.failure, isNotNull);
      await c.verify('fixture-verify');
      expect(c.stage, SessionStage.unauthenticated);
      expect(c.account, isNull);
    });
    test('unverified login enters verification while wrong credentials do not refresh', () async {
      final c = SessionController(DevelopmentAuthRepository(), MemorySessionVault());
      addTearDown(c.dispose);
      await c.login('unverified@example.invalid', 'fixture-only');
      expect(c.stage, SessionStage.awaitingVerification);
      c.show(SessionStage.unauthenticated);
      await c.login('reader@example.invalid', 'wrong');
      expect(c.failure!.kind, FailureKind.unauthorized);
      expect(c.account, isNull);
    });
    test('recovery requires a separate login and Google remains unavailable', () async {
      final c = SessionController(DevelopmentAuthRepository(), MemorySessionVault());
      addTearDown(c.dispose);
      await c.recover('reader@example.invalid');
      expect(c.stage, SessionStage.recoverySent);
      await c.confirmRecovery('fixture-reset', 'new-password');
      expect(c.account, isNull);
      expect(c.stage, SessionStage.unauthenticated);
      await c.google('not-a-real-google-id-token');
      expect(c.failure!.kind, FailureKind.unavailable);
    });
    test('concurrent 401s share refresh; a late old-token 401 uses the new pair', () async {
      final auth = RotatingAuth(), vault = MemorySessionVault();
      final c = SessionController(auth, vault);
      addTearDown(c.dispose);
      await c.login('user', 'secret');
      final a = c.refreshAfterUnauthorized('old-access'), b = c.refreshAfterUnauthorized('old-access');
      expect(auth.refreshCalls, 1);
      final pair = TokenPair(access: 'new-access', refresh: 'new-refresh', expiresAt: DateTime(2030));
      auth.refreshResult.complete(pair);
      await Future.wait([a, b]);
      expect(vault.value, same(pair));
      expect(await c.refreshAfterUnauthorized('old-access'), same(pair));
      expect(auth.refreshCalls, 1);
    });
    test('logout fences a late refresh and clears protected storage', () async {
      final auth = RotatingAuth(), vault = MemorySessionVault();
      final c = SessionController(auth, vault);
      addTearDown(c.dispose);
      await c.login('user', 'secret');
      final refreshing = c.refreshAfterUnauthorized('old-access');
      final rejected = expectLater(refreshing, throwsA(isA<ProductFailure>()));
      await c.signOut();
      auth.refreshResult.complete(TokenPair(access: 'late', refresh: 'late', expiresAt: DateTime(2030)));
      await rejected;
      expect(c.account, isNull);
      expect(vault.value, isNull);
      expect(c.notice, 'localLogout');
    });
    test('uncertain refresh expires the session with no automatic retry', () async {
      final auth = RotatingAuth();
      final c = SessionController(auth, MemorySessionVault());
      addTearDown(c.dispose);
      await c.login('user', 'secret');
      final job = c.refreshAfterUnauthorized('old-access');
      final rejected = expectLater(job, throwsA(isA<ProductFailure>()));
      auth.refreshResult.completeError(const ProductFailure(FailureKind.uncertain));
      await rejected;
      expect(c.stage, SessionStage.expired);
      expect(auth.refreshCalls, 1);
      expect(c.tokens, isNull);
    });
  });
  group('workspace and note transitions', () {
    late DevelopmentKnowledgeRepository repo;
    late WorkspaceController w;
    setUp(() {
      repo = DevelopmentKnowledgeRepository();
      w = WorkspaceController(repo, MemoryAttemptStore(), pollInterval: const Duration(days: 1));
    });
    tearDown(() => w.dispose());
    test('General is recognized by boolean after rename and cannot be deleted', () async {
      await w.openAccount('development-reader');
      final id = w.selected!.id;
      await w.saveProject('Renamed inbox', id: id);
      expect(w.selected!.isGeneral, isTrue);
      expect(w.selected!.name, 'Renamed inbox');
      expect(await w.deleteProject(), isFalse);
      expect(w.selected!.id, id);
    });
    test('save returns queued nullable title, then processing and completed snapshots', () async {
      await w.openAccount('development-other');
      w.updateDraft(content: 'A thought');
      final n = (await w.save())!;
      expect(n.title, isNull);
      expect(n.processing, ProcessingState.queued);
      expect(w.draft.content, isEmpty);
      await w.pollNow();
      expect(w.notes.single.processing, ProcessingState.processing);
      await w.pollNow();
      expect(w.notes.single.processing, ProcessingState.completed);
      expect(w.notes.single.content, 'A thought');
    });
    test('empty note validation retains input without allocating an attempt', () async {
      await w.openAccount('development-other');
      w.updateDraft(content: '  ');
      expect(await w.save(), isNull);
      expect(w.pendingAttempt, isNull);
      expect(w.draft.content, '  ');
      expect(w.failure!.kind, FailureKind.validation);
    });
    test('PATCH preserves omitted versus explicit null title', () async {
      await w.openAccount('development-reader');
      await w.openNote(w.notes.first.id);
      final title = w.detail!.title;
      await w.edit(const NotePatch(content: 'Edited text'));
      expect(w.detail!.title, title);
      expect(w.detail!.processing, ProcessingState.queued);
      expect(const NotePatch(content: 'x').fields.containsKey('title'), isFalse);
      await w.edit(const NotePatch(title: null, includesTitle: true));
      expect(w.detail!.title, isNull);
      expect(const NotePatch(title: null, includesTitle: true).fields['title'], isNull);
    });
    test('acceptance permanently replaces content and queues a new generation', () async {
      await w.openAccount('development-reader');
      await w.openNote(w.notes.first.id);
      final old = w.detail!;
      await w.refine(RefinementAction.accept);
      expect(w.detail!.content, old.proposal);
      expect(w.detail!.proposal, isNull);
      expect(w.detail!.generation, old.generation + 1);
      expect(w.detail!.revision, old.revision + 1);
      expect(w.detail!.processing, ProcessingState.queued);
    });
    test('rejection preserves saved content; regeneration queues without changing revision', () async {
      await w.openAccount('development-reader');
      await w.openNote(w.notes.first.id);
      final old = w.detail!;
      await w.refine(RefinementAction.reject);
      expect(w.detail!.content, old.content);
      expect(w.detail!.proposal, isNull);
      await w.refine(RefinementAction.regenerate);
      expect(w.detail!.revision, old.revision);
      expect(w.detail!.generation, old.generation + 1);
    });
    test('pending processing retry does not start another generation', () async {
      await w.openAccount('development-other');
      w.updateDraft(content: 'Text');
      final n = (await w.save())!;
      final first = await repo.retryProcessing(w.accountId!, n.id);
      final second = await repo.retryProcessing(w.accountId!, n.id);
      expect(first.generation, second.generation);
      expect(first.processing, ProcessingState.queued);
    });
    test('project switch empties scoped search, details and graph', () async {
      await w.openAccount('development-reader');
      await w.loadGraph();
      await w.search('neural');
      expect(w.results, isNotEmpty);
      await w.saveProject('Empty');
      expect(w.results, isNull);
      expect(w.notes, isEmpty);
      expect(w.graph.nodes, isEmpty);
      expect(w.detail, isNull);
    });
    test('project deletion cascades fixture notes and conversations, then selects General', () async {
      await w.openAccount('development-reader');
      final general = w.selected!.id;
      await w.saveProject('Disposable');
      final id = w.selected!.id;
      w.updateDraft(content: 'Disposable note');
      final n = (await w.save())!;
      final chat = await repo.createConversation(w.accountId!, id);
      expect(await w.deleteProject(), isTrue);
      expect(w.selected!.id, general);
      await expectLater(repo.readNote(w.accountId!, n.id), throwsA(isA<ProductFailure>()));
      await expectLater(repo.history(w.accountId!, chat.id), throwsA(isA<ProductFailure>()));
    });
    test('graph contains supplied note edges; newly captured notes stay isolated', () async {
      await w.openAccount('development-reader');
      final original = await repo.graph(w.accountId!, w.selectedProjectId!);
      expect(original.nodes.length, 2);
      expect(original.edges.length, 1);
      w.updateDraft(content: 'neural networks learning');
      await w.save();
      await w.pollNow();
      await w.pollNow();
      await w.loadGraph();
      expect(w.graph.nodes.length, 3);
      expect(w.graph.edges.length, 1);
    });
    test('unknown processing status is safely represented', () {
      expect(ProcessingState.parse('future-state'), ProcessingState.unknown);
    });
  });
  test('uncertain creation reuses the original body, project and key, without duplicates', () async {
    final repo = UncertainCreate(), store = MemoryAttemptStore();
    final w = WorkspaceController(repo, store, pollInterval: const Duration(days: 1));
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: 'Keep this draft');
    expect(await w.save(), isNull);
    final attempt = w.pendingAttempt!;
    expect((await store.read(w.accountId!))!.key, attempt.key);
    w.updateDraft(content: 'Must not replace uncertain payload');
    expect(w.draft.content, 'Keep this draft');
    final saved = await w.save();
    expect(saved, isNotNull);
    expect(repo.sent[0], same(repo.sent[1]));
    expect((await repo.notes(w.accountId!, w.selectedProjectId!)).length, 1);
  });
  test('stale search response cannot appear after changing project', () async {
    final repo = DelayedSearch();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-reader');
    final job = w.search('old query');
    await w.saveProject('New');
    repo.result.complete([const NoteSearchResult(noteId: 'old', title: 'Old', content: 'Old', score: 1)]);
    await job;
    expect(w.results, isNull);
    expect(w.query, isEmpty);
  });
  test('stale proposal reloads current state without replaying the mutation', () async {
    final repo = StaleProposal();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-reader');
    await w.openNote(w.notes.first.id);
    final old = w.detail!.generation;
    expect(await w.refine(RefinementAction.accept), isFalse);
    expect(w.proposalConflict, isTrue);
    expect(w.detail!.generation, old + 1);
    expect(repo.actions, 1);
    expect(w.detailFailure!.kind, FailureKind.conflict);
  });
  group('chat finality and uncertainty', () {
    for (final support in <bool?>[true, false, null]) {
      test('authoritative final replaces preview and preserves supported=$support', () async {
        final repo = ScriptedChat(
          (c) => [
            const ChatDelta('Preview that must disappear'),
            ChatComplete(
              c,
              message('u', 'Question', null, role: 'user'),
              message('a', 'Final authoritative answer', support),
            ),
          ],
        );
        final c = ConversationController(repo);
        addTearDown(c.dispose);
        await c.selectProject('development-reader', (await repo.projects('development-reader')).first.id);
        await c.create();
        c.updateDraft('Question');
        await c.send();
        expect(c.preview, isEmpty);
        expect(c.current!.messages.last.content, 'Final authoritative answer');
        expect(c.current!.messages.last.supported, support);
        expect(c.current!.messages.length, 2);
        expect(c.draft, isEmpty);
      });
    }
    test('zero-delta completion is valid', () async {
      final repo = ScriptedChat(
        (c) => [ChatComplete(c, message('u', 'Hi', null, role: 'user'), message('a', 'Hello', null))],
      );
      final c = ConversationController(repo);
      addTearDown(c.dispose);
      await c.selectProject('development-reader', (await repo.projects('development-reader')).first.id);
      await c.create();
      c.updateDraft('Hi');
      await c.send();
      expect(c.sendState, SendState.idle);
      expect(c.current!.messages.last.content, 'Hello');
    });
    test('EOF retains draft and blocks resending until history has been reloaded', () async {
      final repo = ScriptedChat((_) => [const ChatDelta('Unconfirmed')]);
      final c = ConversationController(repo);
      addTearDown(c.dispose);
      await c.selectProject('development-reader', (await repo.projects('development-reader')).first.id);
      await c.create();
      c.updateDraft('Keep me');
      await c.send();
      expect(c.sendState, SendState.uncertain);
      expect(c.draft, 'Keep me');
      expect(c.canSend, isFalse);
      await c.send();
      expect(repo.sends, 1);
      await c.reconcile();
      expect(repo.histories, 1);
      expect(c.sendState, SendState.reviewed);
      expect(c.canSend, isTrue);
    });
    test('embedded stream error is not a confirmed exchange', () async {
      final repo = ScriptedChat((_) => [const ChatError(ProductFailure(FailureKind.conflict))]);
      final c = ConversationController(repo);
      addTearDown(c.dispose);
      await c.selectProject('development-reader', (await repo.projects('development-reader')).first.id);
      await c.create();
      c.updateDraft('Question');
      await c.send();
      expect(c.current!.messages, isEmpty);
      expect(c.failure!.kind, FailureKind.conflict);
      expect(c.sendState, SendState.uncertain);
    });
  });
  testWidgets('recording automatically stops at 60 seconds and transcription does not create a note', (tester) async {
    final device = TestCaptureDevice(), repo = DevelopmentKnowledgeRepository(stepDelay: Duration.zero);
    final capture = CaptureController(device, repo);
    capture.setAccount('development-other');
    await capture.start();
    expect(capture.state, CaptureState.recording);
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(device.stops, 1);
    expect(capture.state, CaptureState.recorded);
    expect(capture.clip!.duration, CaptureController.maximum);
    final transcription = capture.transcribe();
    await tester.pump(const Duration(milliseconds: 1));
    await transcription;
    expect(capture.state, CaptureState.review);
    expect(capture.transcript, isNotEmpty);
    final project = (await repo.projects('development-other')).first;
    expect(await repo.notes('development-other', project.id), isEmpty);
    capture.dispose();
  });
  test('permission failure never submits a transcription or note', () async {
    final device = TestCaptureDevice()..startError = const ProductFailure(FailureKind.validation, field: 'microphone');
    final capture = CaptureController(device, DevelopmentKnowledgeRepository());
    addTearDown(capture.dispose);
    capture.setAccount('development-other');
    await capture.start();
    expect(capture.state, CaptureState.idle);
    expect(capture.clip, isNull);
    expect(capture.failure!.field, 'microphone');
  });
  test('sign-out clears private controllers; another account receives no previous data', () async {
    final runtime = ProductRuntime(
      DevelopmentAuthRepository(),
      MemorySessionVault(),
      DevelopmentKnowledgeRepository(),
      MemoryAttemptStore(),
      TestCaptureDevice(),
    );
    addTearDown(runtime.dispose);
    await runtime.session.restore();
    await runtime.session.login('reader@example.invalid', 'fixture-only');
    await Future<void>.delayed(Duration.zero);
    expect(runtime.workspace.notes, isNotEmpty);
    runtime.workspace.updateDraft(content: 'Private draft');
    runtime.chat.updateDraft('Private question');
    await runtime.session.signOut();
    expect(runtime.workspace.notes, isEmpty);
    expect(runtime.workspace.draft.content, isEmpty);
    expect(runtime.chat.draft, isEmpty);
    expect(runtime.capture.transcript, isEmpty);
    await runtime.session.login('other@example.invalid', 'fixture-only');
    await Future<void>.delayed(Duration.zero);
    expect(runtime.workspace.notes, isEmpty);
    expect(runtime.workspace.selected!.isGeneral, isTrue);
  });
}
