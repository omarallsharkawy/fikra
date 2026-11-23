import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';

class CountReads extends DevelopmentKnowledgeRepository {
  int reads = 0;
  ProcessingState? force;
  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async {
    reads++;
    final note = await super.readNote(accountId, noteId);
    return force == null ? note : note.copyWith(processing: force);
  }

  @override
  Future<KnowledgeNote> retryProcessing(String accountId, String noteId) async {
    if (force == ProcessingState.failed) {
      final old = await super.readNote(accountId, noteId);
      return old.copyWith(generation: old.generation + 1, processing: ProcessingState.queued);
    }
    return super.retryProcessing(accountId, noteId);
  }
}

class LateProjects extends DevelopmentKnowledgeRepository {
  final held = Completer<List<KnowledgeProject>>();
  @override
  Future<List<KnowledgeProject>> projects(String accountId) =>
      accountId == 'old' ? held.future : super.projects(accountId);
}

class LateStart implements CaptureDevice {
  final started = Completer<void>();
  int cancellations = 0, stops = 0;
  @override
  Future<void> start() => started.future;
  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  Future<RecordedClip?> stop(Duration duration) async {
    stops++;
    return const RecordedClip('/fixture', 'audio/m4a', Duration(seconds: 1));
  }

  @override
  Future<void> dispose() async {}
}

class FailOnce extends DevelopmentKnowledgeRepository {
  bool fail = true;
  final List<CreateAttempt> requests = [];
  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async {
    requests.add(attempt);
    if (fail) {
      fail = false;
      throw const ProductFailure(FailureKind.quota, retryAfter: Duration(seconds: 2));
    }
    return super.createNote(attempt);
  }
}

class DelayedList extends DevelopmentKnowledgeRepository {
  bool hold = false;
  final ready = Completer<List<KnowledgeNote>>();
  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async {
    final snapshot = await super.notes(accountId, projectId);
    if (hold) return ready.future;
    return snapshot;
  }
}

class RejectedAttempt extends DevelopmentKnowledgeRepository {
  final keys = <String>[];
  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async {
    keys.add(attempt.key);
    if (keys.length == 1) throw const ProductFailure(FailureKind.validation);
    return super.createNote(attempt);
  }
}

class ReviewedGeneration extends DevelopmentKnowledgeRepository {
  int? received;
  @override
  Future<KnowledgeNote> refine(String accountId, String noteId, int expectedGeneration, RefinementAction action) {
    received = expectedGeneration;
    return super.refine(accountId, noteId, expectedGeneration, action);
  }
}

void main() {
  test('a late full-list response cannot erase a newer successful save', () async {
    final repo = DelayedList();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    repo.hold = true;
    final reload = w.reload();
    await Future<void>.value();
    w.updateDraft(content: 'Saved after the read started');
    final saved = (await w.save())!;
    repo.ready.complete([]);
    await reload;
    expect(w.notes.single.id, saved.id);
    expect(w.loading, isFalse);
  });
  test('proposal actions retain the generation the user actually reviewed', () async {
    final repo = ReviewedGeneration();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-reader');
    await w.openNote(w.notes.first.id);
    final reviewed = w.detail!;
    await repo.refine(w.accountId!, reviewed.id, reviewed.generation, RefinementAction.regenerate);
    await w.openNote(reviewed.id);
    expect(
      await w.refine(RefinementAction.accept, reviewedNoteId: reviewed.id, expectedGeneration: reviewed.generation),
      isFalse,
    );
    expect(repo.received, reviewed.generation);
    expect(w.proposalConflict, isTrue);
    expect(w.detail!.content, reviewed.content);
  });
  test('a rejected attempt retains input until a new intentional save is reviewed', () async {
    final repo = RejectedAttempt();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: 'Retained');
    await w.save();
    expect(w.canReviewFailedAttempt, isTrue);
    w.updateDraft(content: 'Blocked before review');
    expect(w.draft.content, 'Retained');
    await w.reviewFailedAttempt();
    w.updateDraft(content: 'Repaired');
    await w.save();
    expect(repo.keys[0], isNot(repo.keys[1]));
    expect(w.notes.single.content, 'Repaired');
  });

  testWidgets('polling pauses in background, resumes, and remains bounded', (tester) async {
    final repo = CountReads()..force = ProcessingState.processing;
    final w = WorkspaceController(repo, MemoryAttemptStore(), pollInterval: const Duration(seconds: 1), maxPolls: 1);
    await w.openAccount('development-other');
    w.updateDraft(content: 'Saved pending');
    await w.save();
    w.setForeground(false);
    await tester.pump(const Duration(seconds: 10));
    expect(repo.reads, 0);
    w.setForeground(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(repo.reads, 1);
    expect(w.stillProcessing, isTrue);
    expect(w.notes.single.processing, ProcessingState.processing);
    await tester.pump(const Duration(seconds: 20));
    expect(repo.reads, 1);
    expect(w.notes.single.content, 'Saved pending');
    w.dispose();
  });
  test('a failed processing snapshot keeps saved content and exposes explicit retry', () async {
    final repo = CountReads()..force = ProcessingState.failed;
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: 'Never lose this');
    final note = (await w.save())!;
    await w.openNote(note.id);
    expect(w.detail!.processing, ProcessingState.failed);
    expect(w.detail!.content, 'Never lose this');
    await w.retryProcessing();
    expect(w.detail!.processing.pending, isTrue);
    expect(w.detail!.content, 'Never lose this');
  });
  test('late account bootstrap cannot repopulate signed-out or different-account state', () async {
    final repo = LateProjects();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    final old = w.openAccount('old');
    await Future<void>.value();
    await w.openAccount('development-other');
    repo.held.complete([
      KnowledgeProject(id: 'private-old', name: 'Private', isGeneral: true, createdAt: DateTime.utc(2026)),
    ]);
    await old;
    expect(w.accountId, 'development-other');
    expect(w.projects.any((p) => p.id == 'private-old'), isFalse);
    expect(w.notes, isEmpty);
  });
  test('account change during native start cannot create a recording or transcript for the new account', () async {
    final device = LateStart(), repo = DevelopmentKnowledgeRepository();
    final capture = CaptureController(device, repo);
    addTearDown(capture.dispose);
    capture.setAccount('old');
    final start = capture.start();
    await Future<void>.delayed(Duration.zero);
    capture.setAccount('new');
    device.started.complete();
    await start;
    expect(capture.accountId, 'new');
    expect(capture.state, CaptureState.idle);
    expect(capture.clip, isNull);
    expect(capture.transcript, isEmpty);
  });
  test('quota preserves draft and key and blocks immediate replay', () async {
    final repo = FailOnce();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: 'Retained input');
    await w.save();
    final key = w.pendingAttempt!.key;
    expect(w.failure!.kind, FailureKind.quota);
    expect(w.coolingDown, isTrue);
    await w.save();
    expect(repo.requests.length, 1);
    expect(w.pendingAttempt!.key, key);
    expect(w.draft.content, 'Retained input');
  });
  test('deleted creation replay is gone, and a changed body cannot reuse the key', () async {
    final repo = DevelopmentKnowledgeRepository();
    final project = (await repo.projects('development-other')).first;
    final attempt = CreateAttempt(
      accountId: 'development-other',
      projectId: project.id,
      key: 'one-attempt',
      content: 'Original',
    );
    final note = await repo.createNote(attempt);
    await expectLater(
      repo.createNote(
        CreateAttempt(accountId: attempt.accountId, projectId: attempt.projectId, key: attempt.key, content: 'Changed'),
      ),
      throwsA(isA<ProductFailure>().having((e) => e.kind, 'kind', FailureKind.conflict)),
    );
    await repo.deleteNote(attempt.accountId, note.id);
    await expectLater(
      repo.createNote(attempt),
      throwsA(isA<ProductFailure>().having((e) => e.kind, 'kind', FailureKind.gone)),
    );
  });
  test('missing-title, Unicode code-point and preserved creation timestamp semantics', () async {
    final repo = DevelopmentKnowledgeRepository();
    final w = WorkspaceController(repo, MemoryAttemptStore());
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: '😀' * 60000);
    final note = (await w.save())!;
    expect(note.content.length, 120000);
    expect(note.title, isNull);
    await w.openNote(note.id);
    final created = w.detail!.createdAt;
    await w.edit(const NotePatch(content: 'Edited'));
    expect(w.detail!.createdAt, created);
  });
}
