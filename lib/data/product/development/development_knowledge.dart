import 'dart:async';

import '../../ids.dart';
import '../models.dart';
import '../repositories.dart';

/// Volatile, isolated story fixtures; no LLM, SMTP, HTTP or durable save.
/// Processing snapshots and chat replies are scripted, never inferred from
/// user content. This deliberately does not emulate a general backend.
class DevelopmentKnowledgeRepository implements KnowledgeRepository {
  DevelopmentKnowledgeRepository({this.stepDelay = const Duration(milliseconds: 180)});
  final Duration stepDelay;
  final _projects = <String, List<KnowledgeProject>>{};
  final _notes = <String, Map<String, KnowledgeNote>>{};
  final _attempts = <String, Map<String, (CreateAttempt, String)>>{};
  final _conversations = <String, Map<String, ConversationHistory>>{};
  final _reads = <String, int>{};
  final _edges = <String, List<GraphRelationship>>{};
  DateTime get _now => DateTime.now().toUtc();
  void _seed(String account) {
    if (_projects.containsKey(account)) return;
    final project = KnowledgeProject(id: newId(), name: 'General', isGeneral: true, createdAt: _now);
    _projects[account] = [project];
    _notes[account] = {};
    _attempts[account] = {};
    _conversations[account] = {};
    _edges[account] = [];
    // A second account intentionally starts empty for isolation walkthroughs.
    if (account == 'development-other') return;
    KnowledgeNote sample(String title, String content) => KnowledgeNote(
      id: newId(),
      projectId: project.id,
      title: title,
      content: content,
      concepts: const ['learning'],
      proposal: 'Fixture proposal: review this study plan.',
      revision: 1,
      generation: 1,
      processing: ProcessingState.completed,
      createdAt: _now,
      updatedAt: _now,
    );
    final a = sample('Fixture: neural networks', 'Review neural networks before batch normalization.');
    final b = sample('Fixture: study plan', 'The fixture study plan includes batch normalization.');
    _notes[account]!.addAll({a.id: a, b.id: b});
    _edges[account]!.add(GraphRelationship(a.id, b.id, const ['learning']));
  }

  KnowledgeProject _project(String account, String id) {
    _seed(account);
    return _projects[account]!.firstWhere(
      (p) => p.id == id,
      orElse: () => throw const ProductFailure(FailureKind.notFound),
    );
  }

  KnowledgeNote _note(String account, String id) {
    _seed(account);
    return _notes[account]![id] ?? (throw const ProductFailure(FailureKind.notFound));
  }

  @override
  Future<List<KnowledgeProject>> projects(String accountId) async {
    _seed(accountId);
    return List.of(_projects[accountId]!);
  }

  @override
  Future<KnowledgeProject> createProject(String accountId, String name) async {
    _seed(accountId);
    final project = KnowledgeProject(id: newId(), name: name.trim(), isGeneral: false, createdAt: _now);
    _projects[accountId]!.add(project);
    return project;
  }

  @override
  Future<KnowledgeProject> renameProject(String accountId, String projectId, String name) async {
    final old = _project(accountId, projectId);
    final result = KnowledgeProject(id: old.id, name: name.trim(), isGeneral: old.isGeneral, createdAt: old.createdAt);
    final list = _projects[accountId]!;
    list[list.indexOf(old)] = result;
    return result;
  }

  @override
  Future<void> deleteProject(String accountId, String projectId) async {
    if (_project(accountId, projectId).isGeneral) throw const ProductFailure(FailureKind.conflict);
    final ids = _notes[accountId]!.values.where((n) => n.projectId == projectId).map((n) => n.id).toList();
    for (final id in ids) {
      await deleteNote(accountId, id);
    }
    _conversations[accountId]!.removeWhere((_, h) => h.conversation.projectId == projectId);
    _projects[accountId]!.removeWhere((p) => p.id == projectId);
  }

  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async {
    _project(accountId, projectId);
    return _notes[accountId]!.values.where((n) => n.projectId == projectId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async {
    var note = _note(accountId, noteId);
    if (note.processing.pending) {
      final count = (_reads[noteId] ?? 0) + 1;
      _reads[noteId] = count;
      note = count == 1
          ? note.copyWith(processing: ProcessingState.processing)
          : note.copyWith(
              processing: ProcessingState.completed,
              title: note.title ?? 'Fixture processing result',
              proposal: 'Fixture proposal — no model was called.\n${note.content}',
              concepts: const [],
            );
      _notes[accountId]![noteId] = note;
    }
    return note;
  }

  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async {
    _project(attempt.accountId, attempt.projectId);
    final old = _attempts[attempt.accountId]![attempt.key];
    if (old != null) {
      if (!old.$1.samePayload(attempt)) throw const ProductFailure(FailureKind.conflict);
      return _notes[attempt.accountId]![old.$2] ?? (throw const ProductFailure(FailureKind.gone));
    }
    final note = KnowledgeNote(
      id: newId(),
      projectId: attempt.projectId,
      title: attempt.title,
      content: attempt.content,
      concepts: const [],
      proposal: null,
      revision: 1,
      generation: 1,
      processing: ProcessingState.queued,
      createdAt: _now,
      updatedAt: _now,
    );
    _notes[attempt.accountId]![note.id] = note;
    _attempts[attempt.accountId]![attempt.key] = (attempt, note.id);
    return note;
  }

  KnowledgeNote _queued(String account, KnowledgeNote note) {
    _reads.remove(note.id);
    final next = note.copyWith(processing: ProcessingState.queued, clearProposal: true, updatedAt: _now);
    _notes[account]![note.id] = next;
    return next;
  }

  @override
  Future<KnowledgeNote> updateNote(String accountId, String noteId, NotePatch patch) async {
    final old = _note(accountId, noteId);
    return _queued(
      accountId,
      old.copyWith(
        content: patch.content,
        title: patch.title,
        clearTitle: patch.includesTitle && patch.title == null,
        revision: old.revision + 1,
        generation: old.generation + 1,
      ),
    );
  }

  @override
  Future<KnowledgeNote> retryProcessing(String accountId, String noteId) async {
    final old = _note(accountId, noteId);
    if (old.processing.pending) return old;
    return _queued(accountId, old.copyWith(generation: old.generation + 1));
  }

  @override
  Future<KnowledgeNote> refine(String accountId, String noteId, int expectedGeneration, RefinementAction action) async {
    final old = _note(accountId, noteId);
    if (old.generation != expectedGeneration ||
        (action != RefinementAction.reject && old.processing != ProcessingState.completed) ||
        (action == RefinementAction.accept && old.proposal == null)) {
      throw const ProductFailure(FailureKind.conflict);
    }
    if (action == RefinementAction.reject) {
      final next = old.copyWith(clearProposal: true);
      _notes[accountId]![noteId] = next;
      return next;
    }
    return _queued(
      accountId,
      old.copyWith(
        content: action == RefinementAction.accept ? old.proposal : null,
        revision: old.revision + (action == RefinementAction.accept ? 1 : 0),
        generation: old.generation + 1,
      ),
    );
  }

  @override
  Future<void> deleteNote(String accountId, String noteId) async {
    _note(accountId, noteId);
    _notes[accountId]!.remove(noteId);
    _reads.remove(noteId);
    _edges[accountId]!.removeWhere((e) => e.source == noteId || e.target == noteId);
    _conversations[accountId]!.updateAll(
      (_, h) => ConversationHistory(h.conversation, [
        for (final m in h.messages)
          KnowledgeMessage(
            id: m.id,
            role: m.role,
            content: m.content,
            supported: m.supported,
            createdAt: m.createdAt,
            sources: m.sources.where((s) => s.noteId != noteId).toList(),
          ),
      ]),
    );
  }

  @override
  Future<List<NoteSearchResult>> search(String accountId, String projectId, String query) async => [
    for (final n in await notes(accountId, projectId))
      if (n.processing == ProcessingState.completed &&
          '${n.title} ${n.content}'.toLowerCase().contains(query.toLowerCase()))
        NoteSearchResult(noteId: n.id, title: n.title, content: n.content, score: 1),
  ];
  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) async {
    final nodes = (await notes(accountId, projectId)).where((n) => n.processing == ProcessingState.completed).toList();
    final ids = nodes.map((n) => n.id).toSet();
    return KnowledgeGraph(
      nodes: [
        for (final n in nodes)
          KnowledgeGraphNode(id: n.id, title: n.title, concepts: n.concepts, updatedAt: n.updatedAt),
      ],
      edges: _edges[accountId]!.where((e) => ids.contains(e.source) && ids.contains(e.target)).toList(),
    );
  }

  @override
  Future<List<NoteSourceReference>> related(String accountId, String noteId) async {
    final note = _note(accountId, noteId);
    final data = await graph(accountId, note.projectId);
    final ids = <String>{
      for (final e in data.edges)
        if (e.source == noteId) e.target else if (e.target == noteId) e.source,
    };
    return [
      for (final n in data.nodes)
        if (ids.contains(n.id)) NoteSourceReference(n.id, n.title),
    ];
  }

  @override
  Future<List<Conversation>> conversations(String accountId, String projectId) async {
    _project(accountId, projectId);
    return _conversations[accountId]!.values.map((h) => h.conversation).where((c) => c.projectId == projectId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Conversation> createConversation(String accountId, String projectId) async {
    _project(accountId, projectId);
    final c = Conversation(id: newId(), projectId: projectId, title: null, createdAt: _now, updatedAt: _now);
    _conversations[accountId]![c.id] = ConversationHistory(c, const []);
    return c;
  }

  @override
  Future<ConversationHistory> history(String accountId, String conversationId) async {
    _seed(accountId);
    return _conversations[accountId]![conversationId] ?? (throw const ProductFailure(FailureKind.notFound));
  }

  @override
  Future<void> deleteConversation(String accountId, String conversationId) async {
    await history(accountId, conversationId);
    _conversations[accountId]!.remove(conversationId);
  }

  @override
  Stream<ChatEvent> send(String accountId, String conversationId, String text) async* {
    final history = await this.history(accountId, conversationId);
    yield const ChatDelta('A provisional development preview…');
    await Future<void>.delayed(stepDelay);
    // A fixed social response deliberately avoids a second phrase classifier.
    final c = history.conversation;
    final next = Conversation(
      id: c.id,
      projectId: c.projectId,
      title: c.title ?? text,
      createdAt: c.createdAt,
      updatedAt: _now,
    );
    final user = KnowledgeMessage(id: newId(), role: 'user', content: text, supported: null, createdAt: _now);
    final assistant = KnowledgeMessage(
      id: newId(),
      role: 'assistant',
      content: 'I’m FIKRAH. This is a scripted development reply; no model was called.',
      supported: null,
      createdAt: _now,
    );
    if (!_conversations[accountId]!.containsKey(c.id)) throw const ProductFailure(FailureKind.notFound);
    _conversations[accountId]![c.id] = ConversationHistory(next, [...history.messages, user, assistant]);
    yield ChatComplete(next, user, assistant);
  }

  @override
  Future<String> transcribe(String accountId, RecordedClip recording) async {
    _seed(accountId);
    await Future<void>.delayed(stepDelay);
    return 'Fixture transcript for review. No audio was uploaded or transcribed.';
  }

  @override
  void clearAccount(String accountId) {
    for (final id in _notes[accountId]?.keys ?? <String>[]) {
      _reads.remove(id);
    }
    _projects.remove(accountId);
    _notes.remove(accountId);
    _attempts.remove(accountId);
    _conversations.remove(accountId);
    _edges.remove(accountId);
  }
}
