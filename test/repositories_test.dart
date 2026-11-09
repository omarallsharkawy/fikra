import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/data/processing/note_processor.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/demo/demo_seed.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FikraDatabase db;
  late LocalProjectsRepository projects;
  late LocalNotesRepository notes;

  setUp(() {
    db = FikraDatabase(NativeDatabase.memory());
    projects = LocalProjectsRepository(db);
    notes = LocalNotesRepository(db);
  });
  tearDown(() => db.close());

  test('create project selects it', () async {
    final p = await projects.create('  تجربة ');
    expect(p.name, 'تجربة');
    expect(await projects.watchCurrentId().first, p.id);
  });

  test('original text survives rewrite accept, edit and restore', () async {
    final p = await projects.create('p');
    final n = await notes.create(projectId: p.id, title: '', text: 'نص أصلي', source: NoteSource.text);
    await notes.applyInsights(n.id, _insights(title: 'عنوان مقترح', proposed: 'نص محسّن.'));

    var cur = (await notes.watchNote(n.id).first)!;
    expect(cur.status, ProcessingStatus.ready);
    expect(cur.rewrite, RewriteStatus.pending);
    expect(cur.title, 'عنوان مقترح'); // empty title takes the suggestion

    await notes.acceptRewrite(n.id);
    cur = (await notes.watchNote(n.id).first)!;
    expect(cur.originalText, 'نص أصلي');
    expect(cur.displayText, 'نص محسّن.');
    expect(cur.hasImprovedVersion, isTrue);

    await notes.edit(n.id, title: '', text: 'كتبتها بإيدي');
    cur = (await notes.watchNote(n.id).first)!;
    expect(cur.title, 'عنوان مقترح'); // blank title in the editor keeps the old one
    expect(cur.displayText, 'كتبتها بإيدي');
    expect(cur.originalText, 'نص أصلي');

    await notes.restoreOriginal(n.id);
    cur = (await notes.watchNote(n.id).first)!;
    expect(cur.displayText, 'نص أصلي');
    expect(cur.hasImprovedVersion, isFalse);
  });

  test('deleting a project cascades and moves selection', () async {
    final a = await projects.create('a');
    final b = await projects.create('b');
    await notes.create(projectId: b.id, title: 't', text: 'x', source: NoteSource.text);
    await projects.delete(b.id);
    expect(await notes.notesOf(b.id), isEmpty);
    expect(await projects.watchCurrentId().first, a.id);
  });

  test('demo seed builds linked notes', () async {
    final p = await seedDemoProject(projects, notes);
    final all = await notes.notesOf(p.id);
    expect(all.length, 7);
    expect(all.every((n) => n.status == ProcessingStatus.ready), isTrue);
    expect(await notes.watchLinks(p.id).first, isNotEmpty);
  });

  test('late analysis does not overwrite a title or text the user edited', () async {
    final p = await projects.create('p');
    final n = await notes.create(projectId: p.id, title: '', text: 'الـrag مهم', source: NoteSource.text);
    final insights = _insights(title: 'عنوان الـAI', proposed: 'اقتراح قديم.');
    await notes.edit(n.id, title: 'عنواني', text: 'نص جديد');
    await notes.applyInsights(n.id, insights, basis: n);
    final cur = (await notes.watchNote(n.id).first)!;
    expect(cur.title, 'عنواني');
    expect(cur.displayText, 'نص جديد');
    expect(cur.proposedText, isNull);
    expect(cur.rewrite, isNot(RewriteStatus.pending));
  });

  test('links to other projects, self or duplicates are dropped', () async {
    final a = await projects.create('a');
    final b = await projects.create('b');
    final n1 = await notes.create(projectId: a.id, title: '1', text: 'x', source: NoteSource.text);
    final n2 = await notes.create(projectId: a.id, title: '2', text: 'y', source: NoteSource.text);
    final other = await notes.create(projectId: b.id, title: 'o', text: 'z', source: NoteSource.text);
    await notes.applyInsights(
      n1.id,
      NoteInsights(
        title: '1',
        concepts: const [],
        cluster: 'c',
        links: [
          ProposedLink(targetId: n2.id, label: 'ok', strength: 7),
          ProposedLink(targetId: n2.id, label: 'dup', strength: 0.5),
          ProposedLink(targetId: n1.id, label: 'self', strength: 0.5),
          ProposedLink(targetId: other.id, label: 'cross', strength: 0.5),
          const ProposedLink(targetId: 'missing', label: 'gone', strength: 0.5),
        ],
      ),
    );
    final links = await notes.watchLinks(a.id).first;
    expect(links, hasLength(1));
    expect(links.single.targetId, n2.id);
    expect(links.single.strength, 1.0);
  });

  test('processor runs jobs in order so quick saves still link', () async {
    final p = await projects.create('p');
    final processor = NoteProcessor(notes, DemoAiService(latency: const Duration(milliseconds: 30)));
    final n1 = await notes.create(projectId: p.id, title: 'a', text: 'flutter حلو', source: NoteSource.text);
    final n2 = await notes.create(projectId: p.id, title: 'b', text: 'flutter سريع', source: NoteSource.text);
    await Future.wait([processor.process(n1), processor.process(n2)]);
    final links = await notes.watchLinks(p.id).first;
    expect(links.any((l) => l.sourceId == n2.id && l.targetId == n1.id), isTrue);
  });

  test('a note with a PDF, a recording and photos owns all its files', () async {
    final p = await projects.create('p');
    final dir = await Directory.systemTemp.createTemp('fikra');
    final pdf = await File('${dir.path}/a.pdf').writeAsString('x');
    final voice = await File('${dir.path}/a.m4a').writeAsString('x');
    final photo1 = await File('${dir.path}/1.jpg').writeAsString('x');
    final photo2 = await File('${dir.path}/2.png').writeAsString('x');
    final n = await notes.create(
      projectId: p.id,
      title: 't',
      text: '',
      source: NoteSource.pdf,
      attachmentPath: pdf.path,
      attachmentName: 'a.pdf',
      voicePath: voice.path,
      durationMs: 3000,
      imagePaths: [photo1.path, photo2.path],
    );
    expect(n.hasPdf && n.hasVoice && n.hasImages, isTrue);
    expect(n.imageList, [photo1.path, photo2.path]);
    expect(await notes.attachmentPaths(), {pdf.path, voice.path, photo1.path, photo2.path});

    await notes.delete(n.id);
    for (final f in [pdf, voice, photo1, photo2]) {
      expect(await f.exists(), isFalse);
    }
    await dir.delete(recursive: true);
  });

  test('deleting a project removes the PDF, voice and photo files of its notes', () async {
    final p = await projects.create('p');
    final dir = await Directory.systemTemp.createTemp('fikra');
    final pdf = await File('${dir.path}/b.pdf').writeAsString('x');
    final voice = await File('${dir.path}/b.m4a').writeAsString('x');
    final photo = await File('${dir.path}/b.jpg').writeAsString('x');
    await notes.create(
      projectId: p.id,
      title: 't',
      text: '',
      source: NoteSource.pdf,
      attachmentPath: pdf.path,
      voicePath: voice.path,
      imagePaths: [photo.path],
    );
    await projects.delete(p.id);
    expect(await pdf.exists(), isFalse);
    expect(await voice.exists(), isFalse);
    expect(await photo.exists(), isFalse);
    await dir.delete(recursive: true);
  });

  test('a photo is never stored under an extension that breaks the path list', () {
    expect(AttachmentStore.imageExtension('a.JPEG'), 'jpeg');
    expect(AttachmentStore.imageExtension('no-extension'), 'jpg');
    expect(AttachmentStore.imageExtension('photo.jpg|backup'), 'jpg');
  });

  group('NoteProcessor', () {
    test('a note with nothing typed is ready without calling the AI', () async {
      final p = await projects.create('p');
      final n = await notes.create(
        projectId: p.id,
        title: 'lecture',
        text: '   ',
        source: NoteSource.pdf,
        attachmentPath: '/f/a.pdf',
      );
      final ai = _ScriptedAi([]); // any analyze call would fail on the empty script
      await NoteProcessor(notes, ai).process(n);
      final done = await notes.watchNote(n.id).first;
      expect(done!.status, ProcessingStatus.ready);
      expect(ai.calls, 0);
      expect(done.title, 'lecture');
    });

    test('an attachment does not stop typed text being analyzed', () async {
      final p = await projects.create('p');
      final n = await notes.create(
        projectId: p.id,
        title: '',
        text: 'نص مكتوب',
        source: NoteSource.pdf,
        attachmentPath: '/f/a.pdf',
      );
      final ai = _ScriptedAi([() async => _insights(title: 'ok')]);
      await NoteProcessor(notes, ai).process(n);
      final done = await notes.watchNote(n.id).first;
      expect(done!.status, ProcessingStatus.ready);
      expect(ai.calls, 1);
      expect(done.title, 'ok');
    });

    late Project p;
    setUp(() async => p = await projects.create('p'));

    test('AI failure marks the note failed and the queue keeps going', () async {
      final ai = _ScriptedAi([() => throw Exception('boom'), () async => _insights(title: 'ok')]);
      final processor = NoteProcessor(notes, ai);
      final a = await notes.create(projectId: p.id, title: '', text: 'a', source: NoteSource.text);
      final b = await notes.create(projectId: p.id, title: '', text: 'b', source: NoteSource.text);
      await Future.wait([processor.process(a), processor.process(b)]);
      expect((await notes.watchNote(a.id).first)!.status, ProcessingStatus.failed);
      expect((await notes.watchNote(b.id).first)!.status, ProcessingStatus.ready);
    });

    test('a hung request times out instead of blocking the queue', () async {
      final ai = _ScriptedAi([() => Completer<NoteInsights>().future, () async => _insights(title: 'ok')]);
      final processor = NoteProcessor(notes, ai, timeout: const Duration(milliseconds: 50));
      final a = await notes.create(projectId: p.id, title: '', text: 'a', source: NoteSource.text);
      final b = await notes.create(projectId: p.id, title: '', text: 'b', source: NoteSource.text);
      await Future.wait([processor.process(a), processor.process(b)]);
      expect((await notes.watchNote(a.id).first)!.status, ProcessingStatus.failed);
      expect((await notes.watchNote(b.id).first)!.status, ProcessingStatus.ready);
    });

    test('retry after failure succeeds', () async {
      final ai = _ScriptedAi([() => throw Exception('boom'), () async => _insights(title: 'تاني')]);
      final processor = NoteProcessor(notes, ai);
      final a = await notes.create(projectId: p.id, title: '', text: 'a', source: NoteSource.text);
      await processor.process(a);
      await processor.retry(a.id);
      final cur = (await notes.watchNote(a.id).first)!;
      expect(cur.status, ProcessingStatus.ready);
      expect(cur.title, 'تاني');
    });

    test('resumeInterrupted re-runs notes stuck in processing', () async {
      final processor = NoteProcessor(notes, _ScriptedAi([() async => _insights(title: 'رجعت')]));
      final a = await notes.create(projectId: p.id, title: '', text: 'a', source: NoteSource.text);
      await processor.resumeInterrupted();
      await processor.process(a); // queued behind the resumed job; waits for it
      expect((await notes.watchNote(a.id).first)!.status, ProcessingStatus.ready);
    });
  });
}

NoteInsights _insights({String title = 't', String? proposed, List<ProposedLink> links = const []}) =>
    NoteInsights(title: title, proposedText: proposed, concepts: const ['c'], cluster: 'k', links: links);

/// AiService whose analyze() answers come from a script, one per call
/// (the last entry repeats).
class _ScriptedAi implements AiService {
  _ScriptedAi(this.script);
  final List<Future<NoteInsights> Function()> script;
  var _calls = 0;
  int get calls => _calls;

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) {
    final step = script[_calls < script.length ? _calls : script.length - 1];
    _calls++;
    return step();
  }

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}
