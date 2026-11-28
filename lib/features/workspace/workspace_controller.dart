import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/ids.dart';
import '../../data/product/models.dart';
import '../../data/product/repositories.dart';

class NoteDraft {
  String title = '', content = '';
}

/// Coordinates capabilities; widgets never advance processing or write storage.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController(
    this.repository,
    this.attempts, {
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 12,
    this.onUnauthorized,
  });
  final KnowledgeRepository repository;
  final AttemptStore attempts;
  final Duration pollInterval;
  final int maxPolls;
  final VoidCallback? onUnauthorized;
  String? accountId, selectedProjectId;
  List<KnowledgeProject> projects = const [];
  List<KnowledgeNote> notes = const [];
  KnowledgeNote? detail;
  List<NoteSourceReference> related = const [];
  KnowledgeGraph graph = const KnowledgeGraph();
  List<NoteSearchResult>? results;
  String query = '';
  bool loading = false, busy = false, searching = false, graphLoading = false, detailLoading = false;
  bool stillProcessing = false;
  ProductFailure? failure, attemptFailure, searchFailure, graphFailure, detailFailure;
  DateTime? retryAt;
  CreateAttempt? pendingAttempt;
  int knowledgeRevision = 0, _notesVersion = 0;
  String projectDraft = '';
  String? projectDraftId;
  Timer? _retryWake;
  final _drafts = <String, NoteDraft>{};
  final ValueNotifier<int> draftListenable = ValueNotifier<int>(0);
  final ValueNotifier<bool> draftHasContentListenable = ValueNotifier<bool>(false);
  final _details = <String, KnowledgeNote>{};
  final _relatedByNote = <String, List<NoteSourceReference>>{};
  final _loadingNotes = <String>{};
  final _noteFailures = <String, ProductFailure>{};
  final _noteSequences = <String, int>{};
  final _proposalConflicts = <String>{};
  int _epoch = 0, _searchSequence = 0, _detailSequence = 0, _graphSequence = 0, _pollCount = 0;
  bool _foreground = true, _disposed = false, _polling = false;
  Timer? _pollTimer;
  int get scope => _epoch;
  KnowledgeProject? get selected => projects.where((p) => p.id == selectedProjectId).firstOrNull;
  NoteDraft get draft => _drafts.putIfAbsent(selectedProjectId ?? '', NoteDraft.new);
  bool get coolingDown => retryAt != null && DateTime.now().isBefore(retryAt!);
  bool get proposalConflict => detail != null && _proposalConflicts.contains(detail!.id);
  bool hasProposalConflict(String id) => _proposalConflicts.contains(id);
  KnowledgeNote? detailFor(String id) => _details[id] ?? (detail?.id == id ? detail : null);
  List<NoteSourceReference> relatedFor(String id) =>
      _relatedByNote[id] ?? (detail?.id == id ? related : const []);
  bool isDetailLoading(String id) => _loadingNotes.contains(id);
  ProductFailure? detailFailureFor(String id) => _noteFailures[id];
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  bool _valid(int ticket) => !_disposed && ticket == _epoch && accountId != null;
  ProductFailure _error(Object error) {
    final value = ProductFailure.from(error);
    if (value.kind == FailureKind.quota && value.retryAfter != null) {
      retryAt = DateTime.now().add(value.retryAfter!);
      _retryWake?.cancel();
      _retryWake = Timer(value.retryAfter!, _emit);
    }
    if (value.kind == FailureKind.unauthorized) onUnauthorized?.call();
    return value;
  }

  void clear() {
    _epoch++;
    _searchSequence++;
    _detailSequence++;
    _graphSequence++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _polling = false;
    accountId = null;
    selectedProjectId = null;
    projects = const [];
    notes = const [];
    detail = null;
    related = const [];
    graph = const KnowledgeGraph();
    results = null;
    query = '';
    _drafts.clear();
    _syncDraftSignals(external: true);
    _details.clear();
    _relatedByNote.clear();
    _loadingNotes.clear();
    _noteFailures.clear();
    _noteSequences.clear();
    _proposalConflicts.clear();
    projectDraft = '';
    projectDraftId = null;
    _notesVersion = 0;
    pendingAttempt = null;
    failure = null;
    attemptFailure = null;
    detailFailure = null;
    graphFailure = null;
    searchFailure = null;
    loading = false;
    busy = false;
    searching = false;
    graphLoading = false;
    detailLoading = false;
    _retryWake?.cancel();
    knowledgeRevision = 0;
    retryAt = null;
    stillProcessing = false;
    _emit();
  }

  Future<void> openAccount(String id) async {
    clear();
    accountId = id;
    final ticket = _epoch;
    loading = true;
    _emit();
    try {
      CreateAttempt? restored;
      try {
        restored = await attempts.read(id);
      } catch (_) {
        // Recover cleanly from corrupt/unreadable persisted attempt records.
        unawaited(attempts.clear(id).catchError((Object _) {}));
      }
      if (!_valid(ticket)) return;
      final list = await repository.projects(id);
      if (!_valid(ticket)) return;
      projects = List.unmodifiable(list);
      final general = projects.where((p) => p.isGeneral).firstOrNull;
      if (general == null) throw const ProductFailure(FailureKind.unavailable);
      pendingAttempt = restored;
      if (restored != null) {
        final attempt = restored;
        final targetId = projects.any((p) => p.id == attempt.projectId) ? attempt.projectId : general.id;
        final restoredDraft = _drafts.putIfAbsent(targetId, NoteDraft.new);
        restoredDraft.title = attempt.title ?? '';
        restoredDraft.content = attempt.content;
        _syncDraftSignals(external: true);
      }
      await selectProject(general.id);
    } catch (error) {
      if (_valid(ticket)) {
        failure = _error(error);
        loading = false;
        _emit();
      }
    }
  }

  Future<void> selectProject(String id) async {
    if (accountId == null || !projects.any((p) => p.id == id)) return;
    _epoch++;
    _searchSequence++;
    _detailSequence++;
    _graphSequence++;
    _pollTimer?.cancel();
    _polling = false;
    _pollCount = 0;
    selectedProjectId = id;
    _syncDraftSignals(external: true);
    notes = const [];
    results = null;
    query = '';
    detail = null;
    related = const [];
    _details.clear();
    _relatedByNote.clear();
    _loadingNotes.clear();
    _noteFailures.clear();
    _noteSequences.clear();
    _proposalConflicts.clear();
    graph = const KnowledgeGraph();
    failure = null;
    detailFailure = null;
    searchFailure = null;
    graphFailure = null;
    searching = false;
    graphLoading = false;
    detailLoading = false;
    busy = false;
    stillProcessing = false;
    await reload();
  }

  Future<void> retryWorkspace() async {
    final account = accountId;
    if (account == null) return;
    if (selectedProjectId == null) {
      await openAccount(account);
    } else {
      await reload();
    }
  }

  Future<void> reload() async {
    final account = accountId, project = selectedProjectId, ticket = _epoch;
    if (account == null || project == null) return;
    final version = _notesVersion;
    loading = true;
    stillProcessing = false;
    failure = null;
    _emit();
    try {
      final list = await repository.notes(account, project);
      if (!_valid(ticket)) return;
      if (version != _notesVersion) return;
      notes = List.unmodifiable(list);
      _pollCount = 0;
      _schedulePoll();
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  void _syncDraftSignals({required bool external}) {
    if (_disposed) return;
    final hasContent = draft.content.trim().isNotEmpty;
    if (draftHasContentListenable.value != hasContent) {
      draftHasContentListenable.value = hasContent;
    }
    if (external) draftListenable.value++;
  }

  void updateDraft({String? title, String? content, bool fromInput = false}) {
    if (busy || pendingAttempt != null) return;
    var changed = false;
    if (title != null && draft.title != title) {
      draft.title = title;
      changed = true;
    }
    if (content != null && draft.content != content) {
      draft.content = content;
      changed = true;
    }
    if (changed) _syncDraftSignals(external: !fromInput);
  }

  ProductFailure? _validate(String content, String? title) {
    if (content.trim().isEmpty || content.trim().runes.length > 100000) {
      return const ProductFailure(FailureKind.validation, field: 'content');
    }
    if ((title?.runes.length ?? 0) > 240) return const ProductFailure(FailureKind.validation, field: 'title');
    return null;
  }

  Future<KnowledgeNote?> save() async {
    final account = accountId, project = selectedProjectId, ticket = _epoch;
    if (account == null || project == null || busy || coolingDown) return null;
    final title = draft.title.trim().isEmpty ? null : draft.title.trim();
    final attempt =
        pendingAttempt ??
        CreateAttempt(
          accountId: account,
          projectId: project,
          key: newId(),
          content: draft.content.trim(),
          title: title,
        );
    if (attempt.projectId != project) {
      failure = const ProductFailure(FailureKind.conflict);
      _emit();
      return null;
    }
    failure = _validate(attempt.content, attempt.title);
    if (failure != null) {
      if (pendingAttempt != null) attemptFailure = failure;
      _emit();
      return null;
    }
    busy = true;
    attemptFailure = null;
    _emit();
    try {
      pendingAttempt = attempt;
      await attempts.write(attempt);
      if (!_valid(ticket)) return null;
      final saved = await repository.createNote(attempt);
      if (!_valid(ticket)) return null;
      _upsert(saved);
      pendingAttempt = null;
      attemptFailure = null;
      _drafts.remove(project);
      _syncDraftSignals(external: true);
      try {
        await attempts.clear(account);
      } catch (_) {
        /* Confirmed server write must not become a UI save failure. */
      }
      if (!_valid(ticket)) return null;
      _pollCount = 0;
      _schedulePoll();
      return saved;
    } catch (error) {
      if (_valid(ticket)) {
        failure = _error(error);
        attemptFailure = failure;
      }
      return null;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  bool get canReviewFailedAttempt {
    final attempt = pendingAttempt;
    if (attempt == null) return false;
    if (!projects.any((p) => p.id == attempt.projectId)) return true;
    if (attempt.projectId != selectedProjectId) return false;
    final kind = attemptFailure?.kind;
    return kind == FailureKind.validation ||
        kind == FailureKind.tooLarge ||
        kind == FailureKind.gone ||
        kind == FailureKind.conflict ||
        kind == FailureKind.notFound;
  }

  Future<void> reviewFailedAttempt() async {
    if (!canReviewFailedAttempt || busy || accountId == null) return;
    final account = accountId!, ticket = _epoch;
    try {
      await attempts.clear(account);
    } catch (_) {
      /* Clear in-memory lock even if local attempt storage delete fails. */
    }
    if (!_valid(ticket)) return;
    pendingAttempt = null;
    attemptFailure = null;
    failure = null;
    _emit();
  }

  bool _keepCurrent(KnowledgeNote current, KnowledgeNote incoming) =>
      current.generation > incoming.generation ||
      (current.generation == incoming.generation &&
          (current.updatedAt.isAfter(incoming.updatedAt) ||
              (!current.processing.pending &&
                  current.processing != ProcessingState.unknown &&
                  incoming.processing.pending)));
  void _upsert(KnowledgeNote note) {
    final current = notes.where((n) => n.id == note.id).firstOrNull;
    if (current != null && _keepCurrent(current, note)) return;
    _notesVersion++;
    if (note.projectId != selectedProjectId) return;
    notes = List.unmodifiable(
      [note, ...notes.where((n) => n.id != note.id)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
    if (_details.containsKey(note.id)) _details[note.id] = note;
    if (detail?.id == note.id) detail = note;
  }

  Future<void> openNote(String id) async {
    final account = accountId, ticket = _epoch, seq = ++_detailSequence;
    if (account == null) return;
    final noteSeq = (_noteSequences[id] ?? 0) + 1;
    _noteSequences[id] = noteSeq;
    detail = _details[id];
    related = _relatedByNote[id] ?? const [];
    detailLoading = true;
    detailFailure = null;
    _loadingNotes.add(id);
    _noteFailures.remove(id);
    _proposalConflicts.remove(id);
    _emit();
    try {
      final note = await repository.readNote(account, id);
      if (!_valid(ticket) || _noteSequences[id] != noteSeq) return;
      if (note.projectId != selectedProjectId) throw const ProductFailure(FailureKind.notFound);
      final known = notes.where((n) => n.id == note.id).firstOrNull;
      final resolved = known != null && _keepCurrent(known, note) ? known : note;
      _details[id] = resolved;
      if (seq == _detailSequence) detail = resolved;
      _upsert(resolved);
      _schedulePoll();
      final links = await repository.related(account, id);
      if (_valid(ticket) && _noteSequences[id] == noteSeq) {
        final immutableLinks = List<NoteSourceReference>.unmodifiable(links);
        _relatedByNote[id] = immutableLinks;
        if (seq == _detailSequence) related = immutableLinks;
      }
    } catch (error) {
      if (_valid(ticket) && _noteSequences[id] == noteSeq) {
        final problem = _error(error);
        if (problem.kind == FailureKind.notFound) {
          _details.remove(id);
          _relatedByNote.remove(id);
          _proposalConflicts.remove(id);
          if (detail?.id == id) {
            detail = null;
            related = const [];
          }
          if (notes.any((n) => n.id == id)) {
            _notesVersion++;
            notes = notes.where((n) => n.id != id).toList();
            _invalidateKnowledge();
          }
        }
        _noteFailures[id] = problem;
        if (seq == _detailSequence) detailFailure = problem;
      }
    } finally {
      if (_valid(ticket) && _noteSequences[id] == noteSeq) {
        _loadingNotes.remove(id);
        if (seq == _detailSequence) detailLoading = false;
        _emit();
      }
    }
  }

  Future<bool> _noteMutation(
    Future<KnowledgeNote> Function(String account, KnowledgeNote note) action, {
    String? noteId,
  }) async {
    final account = accountId, note = noteId != null ? detailFor(noteId) : detail, ticket = _epoch;
    if (account == null || note == null || busy || coolingDown) return false;
    busy = true;
    detailFailure = null;
    _noteFailures.remove(note.id);
    _proposalConflicts.remove(note.id);
    _emit();
    try {
      final next = await action(account, note);
      if (!_valid(ticket)) return false;
      _details[next.id] = next;
      _upsert(next);

      _invalidateKnowledge();
      unawaited(_refreshRelated(noteId: next.id));
      _pollCount = 0;
      _schedulePoll();
      return true;
    } catch (error) {
      if (_valid(ticket)) {
        final problem = _error(error);
        detailFailure = problem;
        _noteFailures[note.id] = problem;
        if (problem.kind == FailureKind.conflict) {
          try {
            final fresh = await repository.readNote(account, note.id);
            if (_valid(ticket)) {
              _details[fresh.id] = fresh;
              _upsert(fresh);

              _proposalConflicts.add(fresh.id);
            }
          } catch (_) {
            /* Keep original conflict and require an explicit reload. */
          }
        }
      }
      return false;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<bool> edit(NotePatch patch, {String? noteId}) async {
    final content = patch.content;
    if (patch.fields.isEmpty ||
        (content != null && _validate(content, patch.title) != null) ||
        ((patch.title?.runes.length ?? 0) > 240)) {
      detailFailure = const ProductFailure(FailureKind.validation);
      final targetId = noteId ?? detail?.id;
      if (targetId != null) _noteFailures[targetId] = detailFailure!;
      _emit();
      return false;
    }
    return _noteMutation((account, note) => repository.updateNote(account, note.id, patch), noteId: noteId);
  }

  Future<bool> refine(RefinementAction action, {String? reviewedNoteId, int? expectedGeneration}) => _noteMutation(
    (account, note) {
      if (reviewedNoteId != null && reviewedNoteId != note.id) throw const ProductFailure(FailureKind.conflict);
      return repository.refine(account, note.id, expectedGeneration ?? note.generation, action);
    },
    noteId: reviewedNoteId,
  );
  Future<bool> retryProcessing({String? noteId}) =>
      _noteMutation((account, note) => repository.retryProcessing(account, note.id), noteId: noteId);
  void _invalidateKnowledge() {
    knowledgeRevision++;
    results = null;
    searchFailure = null;
    graph = const KnowledgeGraph();
    related = const [];
    _relatedByNote.clear();
    _searchSequence++;
    _graphSequence++;
  }

  Future<bool> deleteNote({String? noteId}) async {
    final account = accountId, note = noteId != null ? detailFor(noteId) : detail, ticket = _epoch;
    if (account == null || note == null || busy) return false;
    busy = true;
    detailFailure = null;
    _noteFailures.remove(note.id);
    _emit();
    try {
      await repository.deleteNote(account, note.id);
      if (!_valid(ticket)) return false;
      _notesVersion++;
      notes = notes.where((n) => n.id != note.id).toList();
      _details.remove(note.id);
      _relatedByNote.remove(note.id);
      _noteFailures.remove(note.id);
      if (detail?.id == note.id) detail = null;
      _invalidateKnowledge();
      return true;
    } catch (error) {
      if (_valid(ticket)) {
        final problem = _error(error);
        detailFailure = problem;
        _noteFailures[note.id] = problem;
      }
      return false;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> search(String value) async {
    final account = accountId, project = selectedProjectId, ticket = _epoch, seq = ++_searchSequence;
    if (account == null || project == null || coolingDown) return;
    query = value;
    results = null;
    searchFailure = null;
    if (value.trim().isEmpty) {
      searching = false;
      _emit();
      return;
    }
    if (value.trim().runes.length > 4000) {
      searchFailure = const ProductFailure(FailureKind.validation);
      _emit();
      return;
    }
    searching = true;
    _emit();
    try {
      final found = await repository.search(account, project, value.trim());
      if (_valid(ticket) && seq == _searchSequence) results = List.unmodifiable(found);
    } catch (error) {
      if (_valid(ticket) && seq == _searchSequence) searchFailure = _error(error);
    } finally {
      if (_valid(ticket) && seq == _searchSequence) {
        searching = false;
        _emit();
      }
    }
  }

  Future<void> loadGraph() async {
    final account = accountId, project = selectedProjectId, ticket = _epoch, seq = ++_graphSequence;
    if (account == null || project == null) return;
    graph = const KnowledgeGraph();
    graphLoading = true;
    graphFailure = null;
    _emit();
    try {
      final loaded = await repository.graph(account, project);
      if (_valid(ticket) && seq == _graphSequence) graph = loaded;
    } catch (error) {
      if (_valid(ticket) && seq == _graphSequence) graphFailure = _error(error);
    } finally {
      if (_valid(ticket) && seq == _graphSequence) {
        graphLoading = false;
        _emit();
      }
    }
  }

  Future<bool> saveProject(String name, {String? id}) async {
    final account = accountId, ticket = _epoch;
    if (account == null || busy) return false;
    if (name.trim().isEmpty || name.runes.length > 120) {
      failure = const ProductFailure(FailureKind.validation);
      _emit();
      return false;
    }
    projectDraft = name;
    projectDraftId = id;
    busy = true;
    failure = null;
    _emit();
    try {
      final saved = id == null
          ? await repository.createProject(account, name.trim())
          : await repository.renameProject(account, id, name.trim());
      if (!_valid(ticket)) return false;
      projectDraft = '';
      projectDraftId = null;
      projects = List.unmodifiable([
        for (final p in projects)
          if (p.id != saved.id) p,
        saved,
      ]);
      if (id == null) await selectProject(saved.id);
      return true;
    } catch (error) {
      if (_valid(ticket)) {
        failure = _error(error);
        if (id == null && failure?.kind == FailureKind.uncertain) {
          try {
            final refreshed = await repository.projects(account);
            if (_valid(ticket)) projects = List.unmodifiable(refreshed);
          } catch (_) {
            /* Keep the original uncertainty; no automatic create retry. */
          }
        }
      }
      return false;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<bool> deleteProject() async {
    final account = accountId, project = selected, ticket = _epoch;
    if (account == null || project == null || project.isGeneral || busy) return false;
    busy = true;
    failure = null;
    _emit();
    try {
      await repository.deleteProject(account, project.id);
      if (!_valid(ticket)) return false;
      projects = projects.where((p) => p.id != project.id).toList();
      _drafts.remove(project.id);
      _syncDraftSignals(external: true);
      if (pendingAttempt?.projectId == project.id) {
        pendingAttempt = null;
        attemptFailure = null;
        try {
          await attempts.clear(account);
        } catch (_) {
          /* Best-effort attempt cleanup after project deletion. */
        }
        if (!_valid(ticket)) return false;
      }
      final general = projects.where((p) => p.isGeneral).firstOrNull;
      if (general != null) await selectProject(general.id);
      return true;
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
      return false;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> _refreshRelated({String? noteId}) async {
    final account = accountId, note = noteId != null ? detailFor(noteId) : detail, ticket = _epoch;
    if (account == null || note == null || note.processing != ProcessingState.completed) return;
    try {
      final links = await repository.related(account, note.id);
      final current = detailFor(note.id);
      if (_valid(ticket) && current?.id == note.id && current?.generation == note.generation) {
        final immutableLinks = List<NoteSourceReference>.unmodifiable(links);
        _relatedByNote[note.id] = immutableLinks;
        if (detail?.id == note.id) related = immutableLinks;
        _emit();
      }
    } catch (error) {
      if (_valid(ticket)) {
        final problem = _error(error);
        _noteFailures[note.id] = problem;
        if (detail?.id == note.id) detailFailure = problem;
        _emit();
      }
    }
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (value && accountId != null) {
      _pollCount = 0;
      unawaited(reload());
    }
  }

  void _schedulePoll() {
    if (_disposed || !_foreground || _polling || _pollTimer != null || !notes.any((n) => n.processing.pending)) return;
    if (_pollCount >= maxPolls) {
      stillProcessing = true;
      return;
    }
    final multiplier = 1 << (_pollCount ~/ 2).clamp(0, 3);
    _pollTimer = Timer(pollInterval * multiplier, () {
      _pollTimer = null;
      unawaited(pollNow());
    });
  }

  Future<void> pollNow() async {
    final account = accountId, ticket = _epoch;
    if (account == null || !_foreground || _polling) return;
    _polling = true;
    _pollCount++;
    var keepPolling = true;
    try {
      for (final note in notes.where((n) => n.processing.pending).toList()) {
        try {
          final next = await repository.readNote(account, note.id);
          if (!_valid(ticket) || !_foreground) return;
          _upsert(next);
          if (!next.processing.pending) {
            _invalidateKnowledge();
            unawaited(_refreshRelated(noteId: next.id));
            if (detail != null && detail!.id != next.id) {
              unawaited(_refreshRelated(noteId: detail!.id));
            }
          }
        } catch (error) {
          if (!_valid(ticket)) return;
          final problem = _error(error);
          if (problem.kind == FailureKind.notFound) {
            _notesVersion++;
            notes = notes.where((n) => n.id != note.id).toList();
            _details.remove(note.id);
            _relatedByNote.remove(note.id);
            if (detail?.id == note.id) detail = null;
            _invalidateKnowledge();
          } else {
            failure = problem;
            keepPolling = false;
            break;
          }
        }
      }
    } finally {
      if (_valid(ticket)) {
        _polling = false;
        if (keepPolling) _schedulePoll();
        _emit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryWake?.cancel();
    _epoch++;
    _pollTimer?.cancel();
    draftListenable.dispose();
    draftHasContentListenable.dispose();
    super.dispose();
  }
}
