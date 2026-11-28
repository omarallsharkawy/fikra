import '../models.dart';

Map<String, dynamic> object(dynamic value) => value as Map<String, dynamic>;
DateTime date(dynamic value) => DateTime.parse(value as String);
List<String> strings(dynamic value) => List<String>.unmodifiable(value as List);
Account accountFromJson(dynamic value) {
  final x = object(value);
  return Account(id: x['id'], email: x['email'], emailVerified: x['email_verified'], name: x['name'] as String?);
}

TokenPair tokensFromJson(dynamic value, DateTime now) {
  final x = object(value);
  return TokenPair(
    access: x['access_token'],
    refresh: x['refresh_token'],
    expiresAt: now.add(Duration(seconds: (x['expires_in'] as num? ?? 900).toInt())),
  );
}

KnowledgeProject projectFromJson(dynamic value) {
  final x = object(value);
  return KnowledgeProject(id: x['id'], name: x['name'], isGeneral: x['is_general'], createdAt: date(x['created_at']));
}

KnowledgeNote noteFromJson(dynamic value) {
  final x = object(value);
  return KnowledgeNote(
    id: x['id'],
    projectId: x['project_id'],
    title: x['title'],
    content: x['content'],
    concepts: strings(x['concepts']),
    proposal: x['refinement_proposal'],
    revision: x['revision'],
    generation: x['processing_generation'],
    processing: ProcessingState.parse(x['processing_status']),
    createdAt: date(x['created_at']),
    updatedAt: date(x['updated_at']),
    isFavorite: x['is_favorite'] as bool? ?? false,
  );
}

NoteSourceReference sourceFromJson(dynamic value) {
  final x = object(value);
  return NoteSourceReference(x['note_id'], x['title']);
}

Conversation conversationFromJson(dynamic value) {
  final x = object(value);
  return Conversation(
    id: x['id'],
    projectId: x['project_id'],
    title: x['title'],
    createdAt: date(x['created_at']),
    updatedAt: date(x['updated_at']),
  );
}

KnowledgeMessage messageFromJson(dynamic value) {
  final x = object(value);
  return KnowledgeMessage(
    id: x['id'],
    role: x['role'],
    content: x['content'],
    supported: x['supported'],
    createdAt: date(x['created_at']),
    sources: [for (final s in x['sources'] as List) sourceFromJson(s)],
  );
}

KnowledgeGraph graphFromJson(dynamic value) {
  final x = object(value);
  return KnowledgeGraph(
    nodes: [
      for (final v in x['nodes'] as List)
        KnowledgeGraphNode(
          id: v['id'],
          title: v['title'],
          concepts: strings(v['concepts']),
          updatedAt: date(v['updated_at']),
        ),
    ],
    edges: [
      for (final v in x['edges'] as List)
        GraphRelationship(v['source_note_id'], v['target_note_id'], strings(v['shared_concepts'])),
    ],
  );
}
