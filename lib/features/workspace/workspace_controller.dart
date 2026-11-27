import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/ids.dart';
import '../../data/product/local_ui_store.dart';
import '../../data/product/models.dart';
import '../../data/product/repositories.dart';

class NoteDraft {
  String title = '', content = '';
  bool titleVisible = false;
  Set<String> tagIds = {};
  Map<String, Object?> toJson() => {
    'title': title,
    'content': content,
    'title_visible': titleVisible,
    'tag_ids': tagIds.toList(),
  };
}

/// Coordinates capabilities; widgets never advance processing or write storage.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController(
    this.repository,
    this.attempts, {
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 12,
    this.onUnauthorized,
    LocalUiStore? localUi,
  }) : localUi = localUi ?? MemoryLocalUiStore();
  final LocalUiStore localUi;
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
  bool stillProcessing = false, proposalConflict = false;
  ProductFailure? failure, searchFailure, graphFailure, detailFailure;
  DateTime? retryAt;
  CreateAttempt? pendingAttempt;
  int knowledgeRevision = 0, _notesVersion = 0;
  String projectDraft = '';
  String? projectDraftId;
  Timer? _retryWake;
  final _drafts = <String, NoteDraft>{};
  Timer? _draftTimer;
  int _accountEpoch = 0, _draftRevision = 0;
  bool draftsReady = false, draftSaving = false, draftFailure = false, _draftDirty = false;

  Future<void> restoreDrafts() async {
    final account = accountId, ticket = _accountEpoch;
    if (account == null) return;
    try {
      final value = await localUi.read('account:$account');
      if (_disposed || ticket != _accountEpoch) return;
      final records = value['drafts'];
      _drafts.clear();
      if (records is Map) {
        for (final entry in records.entries) {
          final raw = entry.value;
          if (entry.key is! String || raw is! Map || raw['title'] is! String || raw['content'] is! String) continue;
          _drafts[entry.key as String] = NoteDraft()
            ..title = raw['title'] as String
            ..content = raw['content'] as String
            ..titleVisible = raw['title_visible'] == true || (raw['title'] as String).isNotEmpty
            ..tagIds = raw['tag_ids'] is List ? (raw['tag_ids'] as List).whereType<String>().toSet() : <String>{};
        }
      }
      draftsReady = true;
      draftFailure = false;
    } catch (_) {
      if (ticket == _accountEpoch && !_disposed) draftFailure = true;
    }
    if (ticket == _accountEpoch) _emit();
  }

  /// Device autosave never creates an API note. Snapshot before account changes.
  Future<void> flushDraft() async {
    _draftTimer?.cancel();
    final account = accountId, ticket = _accountEpoch, revision = _draftRevision;
    if (account == null || !draftsReady || !_draftDirty) return;
    final snapshot = {for (final e in _drafts.entries) e.key: e.value.toJson()};
    draftSaving = true;
    _emit();
    try {
      await localUi.update('account:$account', (r) => r['drafts'] = snapshot);
      if (ticket == _accountEpoch && !_disposed) {
        if (revision == _draftRevision) _draftDirty = false;
        draftFailure = false;
      }
    } catch (_) {
      if (ticket == _accountEpoch && !_disposed) draftFailure = true;
    } finally {
      if (ticket == _accountEpoch && !_disposed) {
        draftSaving = false;
        _emit();
      }
    }
  }

  int _epoch = 0, _searchSequence = 0, _detailSequence = 0, _graphSequence = 0, _pollCount = 0;
  bool _foreground = true, _disposed = false, _polling = false;
  Timer? _pollTimer;
  int get scope => _epoch;
  KnowledgeProject? get selected => projects.where((p) => p.id == selectedProjectId).firstOrNull;
  NoteDraft get draft => _drafts.putIfAbsent(selectedProjectId ?? '', NoteDraft.new);
  bool get coolingDown => retryAt != null && DateTime.now().isBefore(retryAt!);
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
    unawaited(flushDraft());
    _draftTimer?.cancel();
    _accountEpoch++;
    _draftRevision++;
    draftsReady = false;
    draftFailure = draftSaving = _draftDirty = false;
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
    projectDraft = '';
    projectDraftId = null;
    _notesVersion = 0;
    pendingAttempt = null;
    failure = null;
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
    proposalConflict = false;
    _emit();
  }

  Future<void> openAccount(String id) async {
    clear();
    accountId = id;
    final ticket = _epoch;
    loading = true;
    _emit();
    try {
      await restoreDrafts();
      if (!_valid(ticket)) return;
      final restored = await attempts.read(id);
      if (!_valid(ticket)) return;
      final list = await repository.projects(id);
      if (!_valid(ticket)) return;
      pendingAttempt = restored;
      projects = List.unmodifiable(list);
      final general = projects.where((p) => p.isGeneral).firstOrNull;
      if (general == null) throw const ProductFailure(FailureKind.unavailable);
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
    notes = const [];
    results = null;
    query = '';
    detail = null;
    related = const [];
    graph = const KnowledgeGraph();
    failure = null;
    detailFailure = null;
    searchFailure = null;
    graphFailure = null;
    searching = false;
    graphLoading = false;
    detailLoading = false;
    busy = false;
    proposalConflict = false;
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

  void updateDraft({String? title, String? content, bool? titleVisible, Set<String>? tagIds}) {
    if (busy || pendingAttempt != null || !draftsReady) return;
    if (title != null) draft.title = title;
    if (content != null) draft.content = content;
    if (titleVisible != null) draft.titleVisible = titleVisible;
    if (tagIds != null) draft.tagIds = Set.of(tagIds);
    _draftDirty = true;
    _draftRevision++;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 350), () => unawaited(flushDraft()));
    _emit();
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
    if (account == null || project == null || busy || coolingDown || !draftsReady) return null;
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
      _emit();
      return null;
    }
    busy = true;
    _emit();
    try {
      pendingAttempt = attempt;
      await attempts.write(attempt);
      if (!_valid(ticket)) return null;
      final saved = await repository.createNote(attempt);
      if (!_valid(ticket)) return null;
      _upsert(saved);
      // Keep the original idempotency key until local cleanup succeeds too.
      // A failed local write retries reconciliation, never a second create intent.
      _draftTimer?.cancel();
      await flushDraft();
      if (!_valid(ticket)) return null;
      final selectedTags = draft.tagIds.toList();
      final remainingDrafts = {
        for (final e in _drafts.entries)
          if (e.key != project) e.key: e.value.toJson(),
      };
      await localUi.update('account:$account', (r) {
        r['drafts'] = remainingDrafts;
        if (selectedTags.isNotEmpty) {
          final assignments = r['note_tags'] is Map
              ? Map<String, Object?>.from(r['note_tags'] as Map)
              : <String, Object?>{};
          assignments[saved.id] = selectedTags;
          r['note_tags'] = assignments;
        }
      });
      if (!_valid(ticket)) return null;
      await attempts.clear(account);
      if (!_valid(ticket)) return null;
      pendingAttempt = null;
      _drafts.remove(project);
      _draftDirty = false;
      draftFailure = false;
      _draftRevision++;
      _pollCount = 0;
      _schedulePoll();
      return saved;
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
      return null;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  bool get canReviewFailedAttempt =>
      pendingAttempt != null &&
      (failure?.kind == FailureKind.validation ||
          failure?.kind == FailureKind.tooLarge ||
          failure?.kind == FailureKind.gone);
  Future<void> reviewFailedAttempt() async {
    if (!canReviewFailedAttempt || busy || accountId == null) return;
    final account = accountId!, ticket = _epoch;
    await attempts.clear(account);
    if (!_valid(ticket)) return;
    pendingAttempt = null;
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
    if (detail?.id == note.id) detail = note;
  }

  Future<void> openNote(String id) async {
    final account = accountId, ticket = _epoch, seq = ++_detailSequence;
    if (account == null) return;
    detail = null;
    related = const [];
    detailLoading = true;
    detailFailure = null;
    proposalConflict = false;
    _emit();
    try {
      final note = await repository.readNote(account, id);
      if (!_valid(ticket) || seq != _detailSequence) return;
      if (note.projectId != selectedProjectId) throw const ProductFailure(FailureKind.notFound);
      final known = notes.where((n) => n.id == note.id).firstOrNull;
      detail = known != null && _keepCurrent(known, note) ? known : note;
      _upsert(detail!);
      _schedulePoll();
      final links = await repository.related(account, id);
      if (_valid(ticket) && seq == _detailSequence) related = List.unmodifiable(links);
    } catch (error) {
      if (_valid(ticket) && seq == _detailSequence) detailFailure = _error(error);
    } finally {
      if (_valid(ticket) && seq == _detailSequence) {
        detailLoading = false;
        _emit();
      }
    }
  }

  Future<bool> _noteMutation(
    Future<KnowledgeNote> Function(String account, KnowledgeNote note) action, {
    bool invalidatesKnowledge = true,
  }) async {
    final account = accountId, note = detail, ticket = _epoch;
    if (account == null || note == null || busy || coolingDown) return false;
    busy = true;
    detailFailure = null;
    proposalConflict = false;
    _emit();
    try {
      final next = await action(account, note);
      if (!_valid(ticket)) return false;
      _upsert(next);

      if (invalidatesKnowledge ||
          next.content != note.content ||
          next.generation != note.generation ||
          !listEquals(next.concepts, note.concepts)) {
        _invalidateKnowledge();
        unawaited(_refreshRelated());
      }
      _pollCount = 0;
      _schedulePoll();
      return true;
    } catch (error) {
      if (_valid(ticket)) {
        detailFailure = _error(error);
        if (detailFailure!.kind == FailureKind.conflict) {
          try {
            final fresh = await repository.readNote(account, note.id);
            if (_valid(ticket)) {
              _upsert(fresh);

              proposalConflict = true;
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

  Future<bool> edit(NotePatch patch) async {
    final content = patch.content;
    if (patch.fields.isEmpty ||
        (content != null && _validate(content, patch.title) != null) ||
        ((patch.title?.runes.length ?? 0) > 240)) {
      detailFailure = const ProductFailure(FailureKind.validation);
      _emit();
      return false;
    }
    return _noteMutation((account, note) => repository.updateNote(account, note.id, patch));
  }

  Future<bool> refine(RefinementAction action, {String? reviewedNoteId, int? expectedGeneration}) =>
      _noteMutation((account, note) {
        if (reviewedNoteId != null && reviewedNoteId != note.id) throw const ProductFailure(FailureKind.conflict);
        return repository.refine(account, note.id, expectedGeneration ?? note.generation, action);
      });
  bool get supportsFavorite => repository is FavoriteNotesRepository;
  Future<bool> setFavorite(bool value, {required String reviewedNoteId}) => _noteMutation((account, note) async {
    if (reviewedNoteId != note.id) throw const ProductFailure(FailureKind.conflict);
    final capability = repository;
    if (capability is! FavoriteNotesRepository) throw const ProductFailure(FailureKind.unavailable);
    return (capability as FavoriteNotesRepository).setFavorite(account, note.id, value);
  }, invalidatesKnowledge: false);
  void acceptCommittedChange(String id, KnowledgeNote? note) {
    if (accountId == null) return;
    if (note == null) {
      _notesVersion++;
      notes = List.unmodifiable(notes.where((n) => n.id != id));
      if (detail?.id == id) detail = null;
    } else {
      _upsert(note);
    }
    _invalidateKnowledge();
    if (detail != null) unawaited(_refreshRelated());
    _schedulePoll();
    _emit();
  }

  Future<bool> retryProcessing() => _noteMutation((account, note) => repository.retryProcessing(account, note.id));
  void _invalidateKnowledge() {
    knowledgeRevision++;
    results = null;
    searchFailure = null;
    graph = const KnowledgeGraph();
    related = const [];
    _searchSequence++;
    _graphSequence++;
  }

  Future<bool> deleteNote() async {
    final account = accountId, note = detail, ticket = _epoch;
    if (account == null || note == null || busy) return false;
    busy = true;
    detailFailure = null;
    _emit();
    try {
      await repository.deleteNote(account, note.id);
      if (!_valid(ticket)) return false;
      _notesVersion++;
      notes = notes.where((n) => n.id != note.id).toList();
      detail = null;
      _invalidateKnowledge();
      return true;
    } catch (error) {
      if (_valid(ticket)) detailFailure = _error(error);
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
      if (pendingAttempt?.projectId == project.id) {
        pendingAttempt = null;
        await attempts.clear(account);
      }
      await selectProject(projects.firstWhere((p) => p.isGeneral).id);
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

  Future<void> _refreshRelated() async {
    final account = accountId, note = detail, ticket = _epoch;
    if (account == null || note == null || note.processing != ProcessingState.completed) return;
    try {
      final links = await repository.related(account, note.id);
      if (_valid(ticket) && detail?.id == note.id && detail?.generation == note.generation) {
        related = List.unmodifiable(links);
        _emit();
      }
    } catch (error) {
      if (_valid(ticket)) {
        detailFailure = _error(error);
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
            unawaited(_refreshRelated());
          }
        } catch (error) {
          if (!_valid(ticket)) return;
          final problem = _error(error);
          if (problem.kind == FailureKind.notFound) {
            _notesVersion++;
            notes = notes.where((n) => n.id != note.id).toList();
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
    unawaited(flushDraft());
    _draftTimer?.cancel();
    _disposed = true;
    _retryWake?.cancel();
    _epoch++;
    _pollTimer?.cancel();
    super.dispose();
  }
}
