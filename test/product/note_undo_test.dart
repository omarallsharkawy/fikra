import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/local_ui_store.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/workspace/note_undo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class UndoRepository extends DevelopmentKnowledgeRepository {
  KnowledgeNote? current = KnowledgeNote(
    id: 'n',
    projectId: 'p',
    title: 'A thought',
    content: 'Original content',
    concepts: const [],
    proposal: 'Actual proposal',
    revision: 1,
    generation: 1,
    processing: ProcessingState.completed,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  int deletes = 0, accepts = 0;
  bool uncertain = false;
  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async =>
      current ?? (throw const ProductFailure(FailureKind.notFound));
  @override
  Future<void> deleteNote(String accountId, String noteId) async {
    deletes++;
    current = null;
    if (uncertain) throw const ProductFailure(FailureKind.uncertain);
  }

  @override
  Future<KnowledgeNote> refine(String accountId, String noteId, int expectedGeneration, RefinementAction action) async {
    if (current!.generation != expectedGeneration) throw const ProductFailure(FailureKind.conflict);
    accepts++;
    current = current!.copyWith(
      content: current!.proposal,
      generation: expectedGeneration + 1,
      clearProposal: true,
      processing: ProcessingState.queued,
    );
    if (uncertain) throw const ProductFailure(FailureKind.uncertain);
    return current!;
  }
}

void main() {
  test('Undo cancels before any delete or acceptance request and survives restart', () async {
    final repo = UndoRepository(), store = MemoryLocalUiStore();
    var now = DateTime(2026);
    final undo = NoteUndoController(repo, store, clock: () => now, window: const Duration(hours: 1));
    addTearDown(undo.dispose);
    await undo.bind('owner');
    final queued = await undo.queue(repo.current!, UndoNoteKind.delete);
    expect(undo.hiddenIds, {'n'});
    expect(repo.deletes, 0);
    expect(await undo.undo(queued!.id), isTrue);
    expect(undo.hiddenIds, isEmpty);
    final apply = await undo.queue(repo.current!, UndoNoteKind.apply);
    expect(await undo.undo(apply!.id), isTrue);
    expect(repo.accepts, 0);
    final restarted = NoteUndoController(repo, store, clock: () => now);
    addTearDown(restarted.dispose);
    await restarted.bind('owner');
    expect(restarted.actions, isEmpty);
  });
  for (final kind in UndoNoteKind.values) {
    test('expired $kind reconciles uncertain results without replaying the mutation', () async {
      final repo = UndoRepository(), store = MemoryLocalUiStore();
      var now = DateTime(2026);
      final undo = NoteUndoController(repo, store, clock: () => now, window: const Duration(hours: 1));
      addTearDown(undo.dispose);
      await undo.bind('owner');
      final action = await undo.queue(repo.current!, kind);
      now = now.add(const Duration(hours: 2));
      repo.uncertain = true;
      await undo.flushDue();
      expect(undo.actions.single.state, UndoNoteState.failed);
      expect(kind == UndoNoteKind.delete ? repo.deletes : repo.accepts, 1);
      await undo.retry(action!.id);
      expect(undo.actions, isEmpty);
      expect(kind == UndoNoteKind.delete ? repo.deletes : repo.accepts, 1);
    });
  }
  test('pending action is isolated by account and restores its remaining undo window', () async {
    final repo = UndoRepository(), store = MemoryLocalUiStore();
    var now = DateTime(2026);
    final undo = NoteUndoController(repo, store, clock: () => now, window: const Duration(hours: 1));
    await undo.bind('owner');
    final action = await undo.queue(repo.current!, UndoNoteKind.delete);
    undo.dispose();
    final next = NoteUndoController(repo, store, clock: () => now);
    addTearDown(next.dispose);
    await next.bind('other');
    expect(next.actions, isEmpty);
    expect(repo.deletes, 0);
    await next.bind('owner');
    expect(next.canUndo(next.actions.single), isTrue);
    expect(await next.undo(action!.id), isTrue);
    expect(repo.deletes, 0);
  });
  test('a newer server edit prevents deferred deletion or proposal overwrite', () async {
    for (final kind in UndoNoteKind.values) {
      final repo = UndoRepository(), store = MemoryLocalUiStore();
      var now = DateTime(2026);
      final undo = NoteUndoController(repo, store, clock: () => now, window: const Duration(hours: 1));
      addTearDown(undo.dispose);
      await undo.bind('owner');
      await undo.queue(repo.current!, kind);
      repo.current = repo.current!.copyWith(content: 'Changed elsewhere', revision: 2, generation: 2);
      now = now.add(const Duration(hours: 2));
      await undo.flushDue();
      expect(undo.failure!.kind, FailureKind.conflict);
      expect(undo.actions.single.state, UndoNoteState.failed);
      expect(repo.current!.content, 'Changed elsewhere');
      expect(repo.accepts + repo.deletes, 0);
      expect(undo.hiddenIds, isEmpty);
    }
  });
}
