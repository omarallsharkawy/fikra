import '../local/database.dart';

/// Everything the backend's AI layer does for the app. The demo build uses
/// [DemoAiService]; the connected build will call Alaa's API behind the same
/// interface so screens don't change.
abstract interface class AiService {
  /// Transcribe / extract, rewrite, tag and link a saved note.
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
    this.extractedText,
    this.proposedText,
  });

  final String title;
  final String? extractedText;
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

/// Uploads an attachment and reports progress 0..1. Throws [UploadException].
abstract interface class AttachmentUploader {
  Stream<double> upload({required String path, required String name, required int bytes});
}

class UploadException implements Exception {
  const UploadException(this.message);
  final String message;
  @override
  String toString() => message;
}
