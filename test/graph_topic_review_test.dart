import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/group_form.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

Finder k(String id) => find.byKey(ValueKey(id));

void main() {
  for (final reuse in [false, true]) {
    fikraTest(
      'topic names are grapheme-limited; existing top-level reuse=$reuse has correct Undo',
      locale: const Locale('en'),
      (t, db) async {
        phone(t);
        final notes = await seedGraph(t, db);
        final name = '👨‍👩‍👧‍👦' * (groupNameMaxLength + 3);
        final shortened = name.characters.take(groupNameMaxLength).toString();
        final repo = LocalGroupsRepository(db);
        final existing = await pumpFuture(t, () async {
          final p = await repo.create(notes.first.projectId, 'Parent');
          // A same-named child must not be mistaken for a top-level target.
          await repo.create(notes.first.projectId, shortened, parentId: p.id);
          final top = reuse ? await repo.create(notes.first.projectId, ' $shortened ') : null;
          await (db.update(db.notes)).write(NotesCompanion(cluster: Value(name)));
          return top;
        });
        await pumpAnimations(t);
        final row = graphPaths(t).layout.rows.firstWhere((r) => r.cluster == name);
        final tc = t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
        tc.value = Matrix4.translationValues(0, -row.labelTop + 70, 0);
        await t.pump();
        final control = k('graph-make-group-${row.index}');
        await t.tap(control);
        await settle(t, find.text(enL10n.undo));
        final groups = await allGroups(t, db);
        final top = groups.singleWhere((g) => g.parentId == null && g.name.trim() == shortened);
        expect(top.name.characters.length, groupNameMaxLength);
        if (reuse) expect(top.id, existing!.id);
        expect((await readNote(t, db, notes.first.id)).groupId, top.id);
        expect(groups, hasLength(3));
        await t.tap(find.text(enL10n.undo));
        await pumpAnimations(t);
        await pumpUntil(
          t,
          find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.key == const ValueKey('graph-edges') &&
                (reuse
                    ? !(w.painter as dynamic).paths.layout.frames.any(
                        (f) => f.group.id == top.id && f.noteIds.any((id) => notes.any((n) => n.id == id)),
                      )
                    : !(w.painter as dynamic).paths.layout.frames.any((f) => f.group.id == top.id)),
          ),
        );
        expect((await readNote(t, db, notes.first.id)).groupId, isNull);
        expect((await allGroups(t, db)).any((g) => g.id == top.id), reuse);
      },
    );
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest('hidden suggested-topic card and sheet use topics (${locale.languageCode})', locale: locale, (
      t,
      db,
    ) async {
      phone(t);
      final notes = await seedGraph(t, db, arabic: locale.languageCode == 'ar');
      await pumpFuture(t, () async {
        await LocalGroupsRepository(db).create(notes.first.projectId, 'Empty');
        // Twenty-one topics, above the small-project threshold.
        for (var i = 0; i < 63; i++) {
          await db
              .into(db.notes)
              .insert(
                notes.first.copyWith(
                  id: 't$i',
                  title: 'T $i',
                  cluster: Value('Topic ${i ~/ 3}'),
                  status: ProcessingStatus.ready,
                ),
              );
        }
      });
      await pumpAnimations(t);
      final l = graphPaths(t).layout;
      expect(l.hiddenRows, isNotEmpty);
      final strings = lookupAppLocalizations(locale), label = strings.moreTopicsCount(l.hiddenRows.length);
      final tc = t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
      final p = l.morePosition;
      tc.value = Matrix4.translationValues(60 - p.left, 80 - p.top, 0);
      await t.pump();
      expect(find.text(label), findsOneWidget);
      await t.tap(find.text(label));
      await settle(t, find.text(strings.moreTopics));
      expect(find.text(strings.moreGroups), findsNothing);
    });
  }

  test('more-topic plural forms cover Arabic and English counts', () {
    final ar = arL10n, en = enL10n;
    expect(
      [
        for (final n in [0, 1, 2, 3, 11, 100]) ar.moreTopicsCount(n),
      ],
      ['مفيش مواضيع تانية', 'موضوع تاني', 'موضوعين تانيين', '3 مواضيع تانية', '11 موضوع تاني', '100 موضوع تاني'],
    );
    expect(en.moreTopicsCount(1), '1 more topic');
    expect(en.moreTopicsCount(2), '2 more topics');
  });
}
