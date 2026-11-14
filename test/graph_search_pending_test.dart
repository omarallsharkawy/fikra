import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_navigation_fixture.dart';
import 'support/app_harness.dart';

void main() {
  for (final ar in [false, true]) {
    fikraTest('only ready note search opens its page (ar=$ar)', locale: Locale(ar ? 'ar' : 'en'), (t, db) async {
      navPhone(t);
      final notes = await seedGraph(t, db, arabic: ar);
      await pumpFuture(t, () => (db.delete(db.notes)..where((n) => n.id.equals(notes.first.id).not())).go());
      await navPump(t);
      expect(find.byType(InteractiveViewer), findsNothing);
      await graphQuery(t, notes.first.title);
      await t.tap(navKey('graph-search-note-${notes.first.id}'));
      await navPump(t);
      expect(find.byType(NoteDetailsScreen), findsOneWidget);
      expect(find.text(testL10n(t).graphSearchLimited), findsNothing);
    });
  }

  for (final removed in [false, true]) {
    fikraTest(
      'pending link ${removed ? 'removed' : 'replaced by reverse user pair'} during keyboard wait',
      locale: const Locale('en'),
      (t, db) async {
        navPhone(t);
        final notes = await seedGraph(t, db);
        await graphQuery(t, 'shared topic');
        t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        await navPump(t);
        // Invoking the rendered tile avoids scrolling it past the fake keyboard.
        t.widget<ListTile>(navKey('graph-search-link-ab')).onTap!();
        await t.pump();
        await pumpFuture(t, () async {
          await (db.delete(db.noteLinks)..where((l) => l.id.equals('ab'))).go();
          if (removed) return;
          for (final user in [false, true]) {
            await db
                .into(db.noteLinks)
                .insert(
                  NoteLink(
                    id: user ? 'replacement-user' : 'replacement-ai',
                    projectId: notes.first.projectId,
                    sourceId: user ? notes[1].id : notes[0].id,
                    targetId: user ? notes[0].id : notes[1].id,
                    label: user ? 'user wins' : 'suggested',
                    strength: user ? 0.1 : 1,
                    origin: user ? LinkOrigin.user : LinkOrigin.ai,
                    dismissed: false,
                  ),
                );
          }
        });
        await navPump(t);
        t.view.viewInsets = const FakeViewPadding();
        await navPump(t);
        expect(find.text(testL10n(t).graphSearchLimited), findsNothing);
        expect(find.byType(NoteDetailsScreen), findsNothing);
        if (removed) {
          expect(find.text(testL10n(t).linkRemoved), findsOneWidget);
        } else {
          final edge = graphPaths(t).layout.edges.singleWhere((e) => e.link.id == 'replacement-user');
          expect(edge.link.isUser, isTrue);
          expectCentred(t, Offset(edge.middle.x, edge.middle.y));
          expect(navKey('graph-reason-replacement-user'), findsOneWidget);
        }
      },
    );
  }

  fikraTest(
    'a note moved into a fold during a pending jump is expanded, not called capped',
    locale: const Locale('en'),
    (t, db) async {
      navPhone(t);
      final f = await seedNavigation(t, db);
      await t.tap(navKey('graph-group-collapse-${f.parent.id}'));
      await navPump(t);
      await graphQuery(t, f.notes[5].title);
      t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await navPump(t);
      t.widget<ListTile>(navKey('graph-search-note-${f.notes[5].id}')).onTap!();
      await t.pump();
      await pumpFuture(t, () => LocalGroupsRepository(db).assignNotes(f.parent.id, [f.notes[5].id]));
      await navPump(t);
      t.view.viewInsets = const FakeViewPadding();
      await navPump(t);
      await navPump(t); // The data change required another expansion/layout before travel.
      expect(graphPaths(t).layout.frames.first.collapsed, isFalse);
      final p = graphPaths(t).layout.positions[f.notes[5].id]!;
      expectCentred(t, Offset(p.left + p.width / 2, p.top + p.height / 2));
      expect(find.text(testL10n(t).graphSearchLimited), findsNothing);
      expect(find.byType(NoteDetailsScreen), findsNothing);
    },
  );

  fikraTest('existing pair capped out at 1000 edges opens note with limits message', locale: const Locale('en'), (
    t,
    db,
  ) async {
    navPhone(t);
    final seed = await seedGraph(t, db);
    await pumpFuture(t, () async {
      await db.delete(db.noteLinks).go();
      for (var i = 0; i < 61; i++) {
        await db
            .into(db.notes)
            .insert(
              seed.first.copyWith(
                id: 'cap-$i',
                title: 'Cap $i',
                status: ProcessingStatus.ready,
                cluster: Value('Topic ${i ~/ 12}'),
              ),
            );
      }
      var count = 0;
      for (var a = 0; a < 61 && count < 1001; a++) {
        for (var b = a + 1; b < 61 && count < 1001; b++) {
          final last = count == 1000;
          await db
              .into(db.noteLinks)
              .insert(
                NoteLink(
                  id: 'cap-link-${count++}',
                  projectId: seed.first.projectId,
                  sourceId: 'cap-$a',
                  targetId: 'cap-$b',
                  label: last ? 'Capped reason' : '',
                  strength: last ? 0.01 : 1,
                  origin: LinkOrigin.ai,
                  dismissed: false,
                ),
              );
        }
      }
    });
    await pumpUntil(
      t,
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.key == const ValueKey('graph-edges') &&
            ((w.painter as dynamic).paths.layout.edges.length as int) == 1000,
      ),
    );
    await graphQuery(t, 'Capped reason');
    await t.tap(navKey('graph-search-link-cap-link-1000'));
    await navPump(t);
    expect(find.text(testL10n(t).graphSearchLimited), findsOneWidget);
    expect(find.byType(NoteDetailsScreen), findsOneWidget);
  });
}
