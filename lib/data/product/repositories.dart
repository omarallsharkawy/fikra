import 'models.dart';

abstract interface class AuthRepository {
  bool get isDevelopment;
  Future<Account> currentAccount(TokenPair tokens);
  Future<void> register(String email, String password, {String? name});
  Future<void> verifyEmail(String token, {required String email});
  Future<void> resendVerification(String email);
  Future<SessionGrant> login(String email, String password);
  Future<SessionGrant> exchangeGoogleIdToken(String idToken);
  Future<void> requestRecovery(String email);
  Future<void> confirmRecovery(String token, String password, {required String email});
  Future<TokenPair> refresh(TokenPair current);

  /// false means local sign-out only; do not claim server revocation.
  Future<bool> logout(TokenPair? tokens);
}

abstract interface class SessionVault {
  Future<TokenPair?> read();
  Future<void> replace(TokenPair tokens);
  Future<void> clear();
}

abstract interface class KnowledgeRepository {
  Future<List<KnowledgeProject>> projects(String accountId);
  Future<KnowledgeProject> createProject(String accountId, String name);
  Future<KnowledgeProject> renameProject(String accountId, String projectId, String name);
  Future<void> deleteProject(String accountId, String projectId);
  Future<List<KnowledgeNote>> notes(String accountId, String projectId);
  Future<KnowledgeNote> readNote(String accountId, String noteId);
  Future<KnowledgeNote> createNote(CreateAttempt attempt);
  Future<KnowledgeNote> updateNote(String accountId, String noteId, NotePatch patch);
  Future<void> deleteNote(String accountId, String noteId);
  Future<KnowledgeNote> retryProcessing(String accountId, String noteId);
  Future<KnowledgeNote> refine(String accountId, String noteId, int expectedGeneration, RefinementAction action);
  Future<List<NoteSearchResult>> search(String accountId, String projectId, String query);
  Future<KnowledgeGraph> graph(String accountId, String projectId);
  Future<List<NoteSourceReference>> related(String accountId, String noteId);
  Future<List<Conversation>> conversations(String accountId, String projectId);
  Future<Conversation> createConversation(String accountId, String projectId);
  Future<ConversationHistory> history(String accountId, String conversationId);
  Future<void> deleteConversation(String accountId, String conversationId);
  Stream<ChatEvent> send(String accountId, String conversationId, String text);
  Future<String> transcribe(String accountId, RecordedClip recording);

  /// Clears client-owned private caches, not a backend account deletion.
  void clearAccount(String accountId);
}

abstract interface class AttemptStore {
  Future<CreateAttempt?> read(String accountId);
  Future<void> write(CreateAttempt attempt);
  Future<void> clear(String accountId);
}
