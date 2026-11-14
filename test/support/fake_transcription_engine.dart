import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/local/database.dart';

class FakeTranscriptionEngine implements TranscriptionEngine {
  FakeTranscriptionEngine({this.action});
  Future<String> Function(String path, String language)? action;
  final paths = <String>[];
  final languages = <String>[];
  @override
  String get id => 'local:ggml-small-egy-cs-q5_1.bin';
  @override
  Future<String> transcribe(String audioPath, {required String language}) async {
    paths.add(audioPath);
    languages.add(language);
    return action == null ? 'Test transcript' : action!(audioPath, language);
  }
}

/// Follow-up note processing must not leave demo latency timers after unmount.
class FakeTranscriptionAi implements AiService {
  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async =>
      NoteInsights(title: note.title, concepts: const [], cluster: '', links: const []);
  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) async =>
      const ChatAnswer(text: '', sourceIds: [], found: false);
}
