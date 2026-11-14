import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/processing/transcription_keep_alive.dart';
import 'package:fikra/features/voice_text/transcription_service.dart';
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

/// Records what the queue asks of the Android foreground service.
class FakeTranscriptionKeepAlive implements TranscriptionKeepAlive {
  FakeTranscriptionKeepAlive({this.fail = false});
  final bool fail;
  final events = <String>[];
  @override
  Future<void> start(int remaining) async {
    events.add('start $remaining');
    if (fail) throw StateError('service refused');
  }

  @override
  Future<void> stop() async {
    events.add('stop');
    if (fail) throw StateError('service refused');
  }
}

/// Android 13+ notification permission without the plugin channel.
class FakeNotificationPermission implements TranscriptionNotificationPermission {
  FakeNotificationPermission({this.askable = true});
  bool askable;
  int requests = 0;
  @override
  Future<bool> canAsk() async => askable;
  @override
  Future<void> request() async {
    requests++;
    askable = false;
  }
}
