import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/demo/demo_seed.dart';
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
    final n = await notes.create(projectId: p.id, title: '', text: 'الـrag مهم', source: NoteSource.text);
    final insights = await DemoAiService(latency: Duration.zero).analyze(n, [n]);
    await notes.applyInsights(n.id, insights);

    var cur = (await notes.watchNote(n.id).first)!;
    expect(cur.status, ProcessingStatus.ready);
    expect(cur.rewrite, RewriteStatus.pending);
    expect(cur.title, isNotEmpty);

    await notes.acceptRewrite(n.id);
    cur = (await notes.watchNote(n.id).first)!;
    expect(cur.originalText, 'الـrag مهم');
    expect(cur.displayText, contains('Retrieval-Augmented'));
    expect(cur.hasImprovedVersion, isTrue);

    await notes.restoreOriginal(n.id);
    cur = (await notes.watchNote(n.id).first)!;
    expect(cur.displayText, 'الـrag مهم');
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
    final insights = await DemoAiService(latency: Duration.zero).analyze(n, [n]);
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
      NoteInsights(title: '1', concepts: const [], cluster: 'c', links: [
        ProposedLink(targetId: n2.id, label: 'ok', strength: 7),
        ProposedLink(targetId: n2.id, label: 'dup', strength: 0.5),
        ProposedLink(targetId: n1.id, label: 'self', strength: 0.5),
        ProposedLink(targetId: other.id, label: 'cross', strength: 0.5),
        const ProposedLink(targetId: 'missing', label: 'gone', strength: 0.5),
      ]),
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

  test('deleting a note removes its attachment file', () async {
    final p = await projects.create('p');
    final dir = await Directory.systemTemp.createTemp('fikra');
    final f = await File('${dir.path}/a.m4a').writeAsString('x');
    final n = await notes.create(
        projectId: p.id, title: 't', text: '', source: NoteSource.voice, attachmentPath: f.path);
    await notes.delete(n.id);
    expect(await f.exists(), isFalse);
    await dir.delete(recursive: true);
  });
}
