// Test-only data extracted from the HTML. This file is never an app asset or a
// production repository fallback; it gives both renderers identical content.
import 'dart:convert';
import 'dart:io';

import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';

class HtmlReferenceRepository extends DevelopmentKnowledgeRepository {
  HtmlReferenceRepository(this.language) : super(stepDelay: Duration.zero);
  final String language;
  static final fixture =
      jsonDecode(File('test/support/fixtures/html-reference.json').readAsStringSync()) as Map<String, dynamic>;
  static const projectId = 'reference-general';
  static final project = KnowledgeProject(id: projectId, name: 'General', isGeneral: true, createdAt: DateTime(2026));
  List<Map<String, dynamic>> get rows => (fixture['notes'] as List).cast<Map<String, dynamic>>();
  final _chats = <String, ConversationHistory>{};
  @override
  Future<List<Conversation>> conversations(String accountId, String projectId) async =>
      _chats.values.map((h) => h.conversation).toList();
  @override
  Future<Conversation> createConversation(String accountId, String projectId) async {
    final value = Conversation(
      id: 'reference-chat-${_chats.length}',
      projectId: projectId,
      title: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _chats[value.id] = ConversationHistory(value, const []);
    return value;
  }

  @override
  Future<ConversationHistory> history(String accountId, String conversationId) async => _chats[conversationId]!;
  @override
  Stream<ChatEvent> send(String accountId, String conversationId, String content) async* {
    final old = _chats[conversationId]!, values = await notes(accountId, projectId);
    final answer = (fixture['chat'] as Map)[language]['answer'] as String;
    final user = KnowledgeMessage(
      id: 'reference-user',
      role: 'user',
      content: content,
      supported: null,
      createdAt: DateTime(2026),
    );
    final assistant = KnowledgeMessage(
      id: 'reference-answer',
      role: 'assistant',
      content: answer,
      supported: true,
      createdAt: DateTime(2026),
      sources: values.take(3).map((n) => NoteSourceReference(n.id, n.title)).toList(),
    );
    _chats[conversationId] = ConversationHistory(old.conversation, [user, assistant]);
    yield ChatDelta(answer);
    yield ChatComplete(old.conversation, user, assistant);
  }

  @override
  Future<List<KnowledgeProject>> projects(String accountId) async => [project];
  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async => rows.map((r) {
    final now = DateTime.now();
    final created = DateTime(now.year, now.month, now.day, 1, 56).subtract(Duration(days: r['d'] == 't' ? 0 : 1));
    final diff = (r['df'] as Map?)?[language] as String?;
    final proposal = diff?.replaceAll(RegExp(r'<del>.*?</del>'), '').replaceAll(RegExp('<[^>]+>'), '');
    return KnowledgeNote(
      id: r['id'] as String,
      projectId: projectId,
      title: (r['t'] as Map)[language] as String,
      content: (r['b'] as Map)[language] as String,
      concepts: const [],
      proposal: proposal,
      revision: 1,
      generation: 1,
      processing: r['st'] == 'p' ? ProcessingState.processing : ProcessingState.completed,
      createdAt: created,
      updatedAt: created,
    );
  }).toList();
  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async =>
      (await notes(accountId, projectId)).firstWhere((n) => n.id == noteId);
  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) async {
    final values = await notes(accountId, projectId);
    return KnowledgeGraph(
      nodes: [
        for (final n in values)
          KnowledgeGraphNode(id: n.id, title: n.title, concepts: n.concepts, updatedAt: n.updatedAt),
      ],
      edges: [for (final e in fixture['edges'] as List) GraphRelationship(e[0] as String, e[1] as String, const [])],
    );
  }

  @override
  Future<List<NoteSourceReference>> related(String accountId, String noteId) async {
    final values = await notes(accountId, projectId);
    final ids = <String>{
      for (final e in fixture['edges'] as List)
        if (e.contains(noteId)) (e[0] == noteId ? e[1] : e[0]) as String,
    };
    return [
      for (final n in values)
        if (ids.contains(n.id)) NoteSourceReference(n.id, n.title),
    ];
  }
}
