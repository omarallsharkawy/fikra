import 'package:drift/native.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late LocalLinksRepository links;
  late Project p, q;
  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    notes = LocalNotesRepository(db);
    links = LocalLinksRepository(db);
    p = await LocalProjectsRepository(db).create('p');
    q = await LocalProjectsRepository(db).create('q');
  });
  Future<Note> note() => notes.create(projectId: p.id, title: '', text: 'Text', source: NoteSource.text);
  Future<void> suggest(Note a, Note b) => notes.applyInsights(
    a.id,
    NoteInsights(
      title: '',
      concepts: const [],
      cluster: '',
      links: [ProposedLink(targetId: b.id, label: 'Reason', strength: .8)],
    ),
  );
  Future<PairCommandResult?> act(Note a, Note b, bool accept) => accept
      ? links.acceptPairForUndo(a.id, b.id, expectedProjectId: p.id)
      : links.dismissPairForUndo(a.id, b.id, expectedProjectId: p.id);

  for (final accept in [true, false]) {
    for (final moved in ['source', 'target', 'both']) {
      test('stale $accept action after $moved move changes nothing and returns no undo', () async {
        final a = await note(), b = await note();
        await suggest(a, b);
        await notes.moveNotes([if (moved != 'target') a.id, if (moved != 'source') b.id], q.id);
        final before = await db.select(db.noteLinks).get();
        final result = await act(a, b, accept);
        expect(result, isA<PairCommandStale>());
        expect(result, isNot(isA<PairChange>()));
        expect(await db.select(db.noteLinks).get(), unorderedEquals(before));
      });
    }
    test('valid $accept action followed by Undo restores the exact pair', () async {
      final a = await note(), b = await note();
      await suggest(a, b);
      final before = await db.select(db.noteLinks).get();
      final change = (await act(a, b, accept))! as PairChange;
      expect(await db.select(db.noteLinks).get(), isNot(unorderedEquals(before)));
      expect(await links.undoPairChange(change), isTrue);
      expect(await db.select(db.noteLinks).get(), unorderedEquals(before));
    });
  }

  test('stale dismissal cannot create a tombstone after both notes and the suggestion moved', () async {
    final a = await note(), b = await note();
    await suggest(a, b);
    await notes.moveNotes([a.id, b.id], q.id);
    await db.delete(db.noteLinks).go();
    expect(await act(a, b, false), isA<PairCommandStale>());
    expect(await db.select(db.noteLinks).get(), isEmpty);
  });
}
