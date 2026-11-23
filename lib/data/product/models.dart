/// Backend-owned values. These are separate from the legacy local database.
class Account {
  const Account({required this.id, required this.email, required this.emailVerified});
  final String id;
  final String email;
  final bool emailVerified;
}

class TokenPair {
  const TokenPair({required this.access, required this.refresh, required this.expiresAt});
  final String access;
  final String refresh;
  final DateTime expiresAt;
}

class SessionGrant {
  const SessionGrant(this.account, {this.tokens});
  final Account account;

  /// Development sessions have no real credentials.
  final TokenPair? tokens;
}

class KnowledgeProject {
  const KnowledgeProject({required this.id, required this.name, required this.isGeneral, required this.createdAt});
  final String id;
  final String name;
  final bool isGeneral;
  final DateTime createdAt;
}

enum ProcessingState {
  queued,
  processing,
  completed,
  failed,
  unknown;

  static ProcessingState parse(String value) => values.firstWhere((s) => s.name == value, orElse: () => unknown);
  bool get pending => this == queued || this == processing;
}

class KnowledgeNote {
  const KnowledgeNote({
    required this.id,
    required this.projectId,
    required this.title,
    required this.content,
    required this.concepts,
    required this.proposal,
    required this.revision,
    required this.generation,
    required this.processing,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, projectId, content;
  final String? title, proposal;
  final List<String> concepts;
  final int revision, generation;
  final ProcessingState processing;
  final DateTime createdAt, updatedAt;

  KnowledgeNote copyWith({
    String? content,
    String? title,
    bool clearTitle = false,
    List<String>? concepts,
    String? proposal,
    bool clearProposal = false,
    int? revision,
    int? generation,
    ProcessingState? processing,
    DateTime? updatedAt,
  }) => KnowledgeNote(
    id: id,
    projectId: projectId,
    title: clearTitle ? null : title ?? this.title,
    content: content ?? this.content,
    concepts: List.unmodifiable(concepts ?? this.concepts),
    proposal: clearProposal ? null : proposal ?? this.proposal,
    revision: revision ?? this.revision,
    generation: generation ?? this.generation,
    processing: processing ?? this.processing,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Presence is independent of the value: omitted title differs from null title.
class NotePatch {
  const NotePatch({this.content, this.title, this.includesTitle = false});
  final String? content, title;
  final bool includesTitle;
  Map<String, Object?> get fields => {if (content != null) 'content': content, if (includesTitle) 'title': title};
}

class CreateAttempt {
  const CreateAttempt({
    required this.accountId,
    required this.projectId,
    required this.key,
    required this.content,
    this.title,
  });
  final String accountId, projectId, key, content;
  final String? title;
  bool samePayload(CreateAttempt other) =>
      accountId == other.accountId && projectId == other.projectId && content == other.content && title == other.title;
}

enum RefinementAction { accept, reject, regenerate }

class NoteSourceReference {
  const NoteSourceReference(this.noteId, this.title);
  final String noteId;
  final String? title;
}

class GraphRelationship {
  const GraphRelationship(this.source, this.target, this.sharedConcepts);
  final String source, target;
  final List<String> sharedConcepts;
}

class KnowledgeGraphNode {
  const KnowledgeGraphNode({required this.id, required this.title, required this.concepts, required this.updatedAt});
  final String id;
  final String? title;
  final List<String> concepts;
  final DateTime updatedAt;
}

class KnowledgeGraph {
  const KnowledgeGraph({this.nodes = const [], this.edges = const []});
  final List<KnowledgeGraphNode> nodes;
  final List<GraphRelationship> edges;
}

class NoteSearchResult {
  const NoteSearchResult({required this.noteId, required this.title, required this.content, required this.score});
  final String noteId, content;
  final String? title;
  final double score;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.projectId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, projectId;
  final String? title;
  final DateTime createdAt, updatedAt;
}

class KnowledgeMessage {
  const KnowledgeMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.supported,
    required this.createdAt,
    this.sources = const [],
  });
  final String id, role, content;
  final bool? supported;
  final DateTime createdAt;
  final List<NoteSourceReference> sources;
}

class ConversationHistory {
  const ConversationHistory(this.conversation, this.messages);
  final Conversation conversation;
  final List<KnowledgeMessage> messages;
}

sealed class ChatEvent {
  const ChatEvent();
}

class ChatDelta extends ChatEvent {
  const ChatDelta(this.content);
  final String content;
}

class ChatComplete extends ChatEvent {
  const ChatComplete(this.conversation, this.user, this.assistant);
  final Conversation conversation;
  final KnowledgeMessage user, assistant;
}

class ChatError extends ChatEvent {
  const ChatError(this.failure);
  final ProductFailure failure;
}

enum FailureKind {
  validation,
  unauthorized,
  unverified,
  notFound,
  conflict,
  gone,
  tooLarge,
  mediaType,
  quota,
  unavailable,
  uncertain,
}

class ProductFailure implements Exception {
  const ProductFailure(this.kind, {this.retryAfter, this.field});
  final FailureKind kind;
  final Duration? retryAfter;
  final String? field;
  static ProductFailure from(Object error) =>
      error is ProductFailure ? error : const ProductFailure(FailureKind.uncertain);
  // No private request or exception payload is exposed to logging/UI.
  @override
  String toString() => 'ProductFailure(${kind.name})';
}

class RecordedClip {
  const RecordedClip(this.path, this.mimeType, this.duration);
  final String path, mimeType;
  final Duration duration;
}
