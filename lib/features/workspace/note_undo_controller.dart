import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/ids.dart';
import '../../data/product/local_ui_store.dart';
import '../../data/product/models.dart';
import '../../data/product/repositories.dart';

enum UndoNoteKind { delete, apply }

enum UndoNoteState { queued, committing, failed }

class UndoNoteAction {
  const UndoNoteAction({
    required this.id,
    required this.noteId,
    required this.projectId,
    required this.kind,
    required this.deadline,
    required this.generation,
    required this.revision,
    required this.before,
    this.proposal,
    this.state = UndoNoteState.queued,
  });
  final String id, noteId, projectId, before;
  final String? proposal;
  final UndoNoteKind kind;
  final DateTime deadline;
  final int generation, revision;
  final UndoNoteState state;
  UndoNoteAction withState(UndoNoteState value) => UndoNoteAction(
    id: id,
    noteId: noteId,
    projectId: projectId,
    kind: kind,
    deadline: deadline,
    generation: generation,
    revision: revision,
    before: before,
    proposal: proposal,
    state: value,
  );
  Map<String, Object?> get json => {
    'id': id,
    'note_id': noteId,
    'project_id': projectId,
    'kind': kind.name,
    'deadline': deadline.toUtc().toIso8601String(),
    'generation': generation,
    'revision': revision,
    'before': before,
    'proposal': proposal,
    'state': state.name,
  };
  static UndoNoteAction parse(Map value) => UndoNoteAction(
    id: value['id'] as String,
    noteId: value['note_id'] as String,
    projectId: value['project_id'] as String,
    kind: UndoNoteKind.values.byName(value['kind'] as String),
    deadline: DateTime.parse(value['deadline'] as String),
    generation: value['generation'] as int,
    revision: value['revision'] as int,
    before: value['before'] as String,
    proposal: value['proposal'] as String?,
    state: UndoNoteState.values.byName(value['state'] as String),
  );
}

/// Undo cancels a durable deferred operation; it never recreates deleted IDs or
/// overwrites newer server content with an old local copy.
class NoteUndoController extends ChangeNotifier {
  NoteUndoController(
    this.repository,
    this.store, {
    this.clock = DateTime.now,
    this.window = const Duration(seconds: 5),
    this.onCommitted,
    this.onUnauthorized,
  });
  final KnowledgeRepository repository;
  final LocalUiStore store;
  final DateTime Function() clock;
  final Duration window;
  final void Function(UndoNoteAction action, KnowledgeNote? note)? onCommitted;
  final VoidCallback? onUnauthorized;
  String? accountId;
  List<UndoNoteAction> actions = const [];
  ProductFailure? failure;
  bool loading = false;
  int _epoch = 0;
  bool _disposed = false;
  Timer? _timer;
  Future<void> _writes = Future.value();
  final _executing = <String>{}, _blocked = <String>{}, _cancelling = <String>{};
  Set<String> get hiddenIds => actions
      .where((a) => a.kind == UndoNoteKind.delete && a.state != UndoNoteState.failed)
      .map((a) => a.noteId)
      .toSet();
  UndoNoteAction? forNote(String id) =>
      actions.where((a) => a.noteId == id && a.state != UndoNoteState.failed).firstOrNull;
  bool retryable(UndoNoteAction action) => action.state == UndoNoteState.failed || _blocked.contains(action.id);
  bool canUndo(UndoNoteAction action) =>
      action.state == UndoNoteState.queued &&
      !_executing.contains(action.id) &&
      !_cancelling.contains(action.id) &&
      clock().isBefore(action.deadline);
  bool _valid(int ticket) => !_disposed && ticket == _epoch && accountId != null;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> bind(String? id) async {
    final ticket = ++_epoch;
    _timer?.cancel();
    _executing.clear();
    _blocked.clear();
    _cancelling.clear();
    accountId = id;
    actions = const [];
    failure = null;
    loading = id != null;
    _emit();
    if (id == null) return;
    try {
      final record = await store.read('account:$id');
      if (!_valid(ticket)) return;
      final raw = record['pending_note_actions'];
      actions = raw is List ? List.unmodifiable(raw.whereType<Map>().map(UndoNoteAction.parse)) : const [];
      if (actions.any((a) => a.state == UndoNoteState.failed)) failure = const ProductFailure(FailureKind.uncertain);
    } catch (_) {
      if (_valid(ticket)) failure = const ProductFailure(FailureKind.unavailable);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
        _schedule();
      }
    }
  }

  Future<bool> _replace(List<UndoNoteAction>? Function(List<UndoNoteAction>) change) {
    final result = Completer<bool>(), id = accountId, ticket = _epoch;
    _writes = _writes.then((_) async {
      if (id == null || !_valid(ticket)) {
        result.complete(false);
        return;
      }
      try {
        final next = change(actions);
        if (next == null) {
          result.complete(false);
          return;
        }
        await store.update('account:$id', (r) => r['pending_note_actions'] = [for (final a in next) a.json]);
        if (!_valid(ticket)) {
          result.complete(false);
          return;
        }
        actions = List.unmodifiable(next);
        if (actions.isEmpty) failure = null;
        _emit();
        _schedule();
        result.complete(true);
      } catch (_) {
        if (_valid(ticket)) {
          failure = const ProductFailure(FailureKind.unavailable);
          _emit();
        }
        result.complete(false);
      }
    });
    return result.future;
  }

  Future<UndoNoteAction?> queue(KnowledgeNote note, UndoNoteKind kind) async {
    if (loading || accountId == null || (kind == UndoNoteKind.apply && note.proposal == null)) return null;
    final action = UndoNoteAction(
      id: newId(),
      noteId: note.id,
      projectId: note.projectId,
      kind: kind,
      deadline: clock().add(window),
      generation: note.generation,
      revision: note.revision,
      before: note.content,
      proposal: note.proposal,
    );
    final ok = await _replace((current) => current.any((a) => a.noteId == note.id) ? null : [...current, action]);
    return ok ? action : null;
  }

  Future<bool> undo(String id) async {
    final action = actions.where((a) => a.id == id).firstOrNull, ticket = _epoch;
    if (action == null || !canUndo(action)) return false;
    _cancelling.add(id);
    _schedule();
    final ok = await _replace(
      (current) => current.any((a) => a.id == id && a.state == UndoNoteState.queued) && !_executing.contains(id)
          ? current.where((a) => a.id != id).toList()
          : null,
    );
    if (_valid(ticket)) {
      _cancelling.remove(id);
      if (!ok) _blocked.add(id);
      _schedule();
    }
    return ok;
  }

  Future<bool> discardFailed(String id) async {
    final ok = await _replace(
      (current) => current.any((a) => a.id == id && a.state == UndoNoteState.failed)
          ? current.where((a) => a.id != id).toList()
          : null,
    );
    if (ok) {
      _blocked.remove(id);
      if (!actions.any(retryable)) {
        failure = null;
        _emit();
      }
    }
    return ok;
  }

  Future<void> retry(String id) async {
    final action = actions.where((a) => a.id == id).firstOrNull;
    if (action == null) return;
    _blocked.remove(id);
    failure = null;
    await _commit(action);
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || loading || accountId == null) return;
    final ready = actions
        .where(
          (a) =>
              a.state != UndoNoteState.failed &&
              !_executing.contains(a.id) &&
              !_blocked.contains(a.id) &&
              !_cancelling.contains(a.id),
        )
        .toList();
    if (ready.isEmpty) return;
    ready.sort((a, b) => a.deadline.compareTo(b.deadline));
    final delay = ready.first.state == UndoNoteState.committing
        ? Duration.zero
        : ready.first.deadline.difference(clock());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () => unawaited(flushDue()));
  }

  Future<void> flushDue() async {
    for (final action in List.of(actions)) {
      if (action.state != UndoNoteState.failed &&
          !_blocked.contains(action.id) &&
          (action.state == UndoNoteState.committing || !clock().isBefore(action.deadline))) {
        await _commit(action);
      }
    }
    _schedule();
  }

  Future<void> _commit(UndoNoteAction action) async {
    final id = accountId, ticket = _epoch;
    if (id == null || _executing.contains(action.id) || _cancelling.contains(action.id)) return;
    _executing.add(action.id);
    try {
      final marked = await _replace(
        (current) => current.any((a) => a.id == action.id)
            ? [for (final a in current) a.id == action.id ? a.withState(UndoNoteState.committing) : a]
            : null,
      );
      if (!marked) {
        _blocked.add(action.id);
        return;
      }
      if (!_valid(ticket)) return;
      KnowledgeNote? result;
      try {
        final current = await repository.readNote(id, action.noteId);
        if (!_valid(ticket)) return;
        if (action.kind == UndoNoteKind.delete) {
          if (current.revision != action.revision || current.content != action.before) {
            throw const ProductFailure(FailureKind.conflict);
          }
          await repository.deleteNote(id, action.noteId);
        } else {
          // A previous uncertain acceptance may already have completed.
          if (current.content == action.proposal && current.generation != action.generation) {
            result = current;
          } else {
            if (current.generation != action.generation ||
                current.content != action.before ||
                current.proposal != action.proposal) {
              throw const ProductFailure(FailureKind.conflict);
            }
            result = await repository.refine(id, action.noteId, action.generation, RefinementAction.accept);
          }
        }
      } on ProductFailure catch (e) {
        if (e.kind != FailureKind.notFound || action.kind != UndoNoteKind.delete) rethrow;
      }
      if (!_valid(ticket)) return;
      // Server truth is reflected even if clearing the local journal fails.
      // The retained committing entry is reconciled safely on the next retry.
      onCommitted?.call(action, result);
      final cleared = await _replace((current) => current.where((a) => a.id != action.id).toList());
      if (!cleared) _blocked.add(action.id);
    } catch (error) {
      if (!_valid(ticket)) return;
      failure = ProductFailure.from(error);
      if (failure!.kind == FailureKind.unauthorized) onUnauthorized?.call();
      final marked = await _replace(
        (current) => [for (final a in current) a.id == action.id ? a.withState(UndoNoteState.failed) : a],
      );
      if (!marked) _blocked.add(action.id);
      _emit();
    } finally {
      if (_valid(ticket)) {
        _executing.remove(action.id);
        _schedule();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _timer?.cancel();
    super.dispose();
  }
}
