import '../local/database.dart';

/// Everything the backend's AI layer does for the app. The demo build uses
/// [DemoAiService]; the connected build will call Alaa's API behind the same
/// interface so screens don't change.
abstract interface class AiService {
  /// Rewrite, tag and link a saved note from its typed text ([Note.originalText]).
  /// NoteProcessor appends saved voice transcripts to that field for analysis.
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes);

  /// Answer a question using only the notes of one project.
  Future<ChatAnswer> ask(String question, List<Note> projectNotes);
}

class NoteInsights {
  const NoteInsights({
    required this.title,
    required this.concepts,
    required this.cluster,
    required this.links,
    this.proposedText,
  });

  final String title;
  final String? proposedText;
  final List<String> concepts;
  final String cluster;
  final List<ProposedLink> links;
}

class ProposedLink {
  const ProposedLink({required this.targetId, required this.label, required this.strength});
  final String targetId;
  final String label;
  final double strength;
}

class ChatAnswer {
  const ChatAnswer({required this.text, required this.sourceIds, required this.found});
  final String text;
  final List<String> sourceIds;
  final bool found;
}
