import 'dart:io';

import 'package:fikra/core/format.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/shared/move_confirm.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  final ar = arL10n;
  final en = enL10n;
  bool selecting() => find.byType(SelectionHeader).evaluate().isNotEmpty;

  group('link together', () {
    late SpyLinks spy;
    fikraTest(
      'three notes get three links in two calls; Undo removes them',
      linksRepository: (db) => spy = SpyLinks(db),
      (tester, db) async {
        phone(tester);
        final (_, _, [a, b, c, d]) = await seedNotes(tester, db, ['A', 'B', 'C', 'D']);
        await select(tester, [a, b, c]);
        await tapAction(tester, 'link');
        await settle(tester, find.text(ar.linksAdded(3)));
        expect(spy.linkCalls, 2);
        expect(await userPairs(tester, db), {
          {a.id, b.id},
          {a.id, c.id},
          {b.id, c.id},
        });
        expect((await allLinks(tester, db)).every((l) => l.label.isEmpty), isTrue);
        expect(selecting(), isFalse);
        expect(d.id, isNot(anyOf(a.id, b.id, c.id)));
        await tester.tap(find.text(ar.undo));
        await pumpAnimations(tester);
        await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
        expect(await userPairs(tester, db), isEmpty);
        // The pairs had no row before, and have none again.
        expect(await allLinks(tester, db), isEmpty);
      },
    );

    fikraTest('Undo keeps a link that existed before; all linked already says so with no Undo', (tester, db) async {
      phone(tester);
      final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
      await insertLink(tester, db, b, a);
      await select(tester, [a, b, c]);
      await tapAction(tester, 'link');
      await settle(tester, find.text(ar.linksAdded(2)));
      expect((await userPairs(tester, db)).length, 3);
      await tester.tap(find.text(ar.undo));
      await pumpAnimations(tester);
      await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect(await userPairs(tester, db), {
        {a.id, b.id},
      });

      await select(tester, [a, b]);
      await tapAction(tester, 'link');
      await settle(tester, find.text(ar.linksAdded(0)));
      expect(find.text(ar.undo), findsNothing);
      expect(await userPairs(tester, db), {
        {a.id, b.id},
      });
    });

    fikraTest(
      'a failed call removes the links made so far and keeps the selection',
      linksRepository: (db) => spy = SpyLinks(db)..failOn = 2,
      (tester, db) async {
        phone(tester);
        final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
        await select(tester, [a, b, c]);
        await tapAction(tester, 'link');
        await settle(tester, find.text(ar.linkFailed));
        expect(spy.linkCalls, 2);
        expect(await userPairs(tester, db), isEmpty);
        expect(selecting(), isTrue);
        expect(find.text(ar.selectedCount(3)), findsOneWidget);
      },
    );
  });

  group('move', () {
    for (final l10n in [ar, en]) {
      late SpyNotes spy;
      fikraTest(
        'three notes: the numbers shown are what goes, inner links stay, changed numbers ask again (${l10n.localeName})',
        locale: Locale(l10n.localeName),
        notesRepository: (db) => spy = SpyNotes(db),
        aiService: QuietAi(),
        (tester, db) async {
          phone(tester);
          final (p, q, [a, b, c, d, e]) = await seedNotes(
            tester,
            db,
            ['A', 'B', 'C', 'D', 'E'],
            l10n: l10n,
            files: {
              0: ['/private/a.pdf', '/private/a2.pdf'],
            },
          );
          await insertLink(tester, db, a, b); // inside the selection: stays
          await insertLink(tester, db, a, d); // crossing: removed
          await insertLink(tester, db, d, c, origin: LinkOrigin.ai); // crossing suggestion: removed
          await insertLink(tester, db, d, e); // not touched
          final files = await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(a.id).first);
          await select(tester, [a, b, c]);
          await tapAction(tester, 'move');
          expect(find.byKey(ValueKey('project-pick-${p.id}')), findsNothing);
          await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
          final title = l10n.moveNotesTitle(Fmt.notes(l10n, 3), Fmt.isolate('Work'));
          await settle(tester, find.text(title));
          final first = moveMessage(l10n, (userLinks: 1, suggestions: 1), notes: 3);
          expect(find.text(first), findsOneWidget);
          expect(
            first,
            l10n.localeName == 'ar'
                ? 'الملاحظات هتتنقل بملفاتها، وهيتشال رابط واحد واقتراح واحد بينها وبين الملاحظات اللي هتفضل هنا.'
                : 'The notes move with their files. Their 1 link and 1 suggestion to notes that stay here will be removed.',
          );
          // A new crossing link while the dialog is open: asked again.
          await insertLink(tester, db, e, b);
          await tester.tap(find.text(l10n.moveConfirm).last);
          await settle(tester, find.text(moveMessage(l10n, (userLinks: 2, suggestions: 1), notes: 3)));
          expect(spy.moves, 0);
          final crossing = (await allLinks(
            tester,
            db,
          )).where((l) => {a.id, b.id, c.id}.contains(l.sourceId) != {a.id, b.id, c.id}.contains(l.targetId));
          expect(crossing.length, 3); // 2 links + 1 suggestion, as shown
          await tester.tap(find.text(l10n.moveConfirm).last);
          await settle(tester, find.text(l10n.notesMoved(Fmt.notes(l10n, 3), Fmt.isolate('Work'))));
          expect(spy.moves, 1);
          for (final n in [a, b, c]) {
            expect((await readNote(tester, db, n.id)).projectId, q.id);
          }
          final left = await allLinks(tester, db);
          expect(left.where((l) => crossing.any((x) => x.id == l.id)), isEmpty);
          expect(left.singleWhere((l) => l.sourceId == a.id && l.targetId == b.id).projectId, q.id);
          expect(left.where((l) => l.sourceId == d.id && l.targetId == e.id), hasLength(1));
          expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(a.id).first), files);
          expect(selecting(), isFalse);
          expect(find.text('A'), findsNothing);
          for (var i = 0; i < 20 && spy.relinked.length < 3; i++) {
            await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 10)));
          }
          expect(spy.relinked.toSet(), {a.id, b.id, c.id});
        },
      );
    }

    late SpyNotes spy;
    fikraTest(
      'a double tap opens one picker; cancel keeps the selection',
      notesRepository: (db) => spy = SpyNotes(db),
      (tester, db) async {
        phone(tester);
        final (_, q, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
        await select(tester, [a, b]);
        // Both taps reach the handler (a real second tap may land on the sheet).
        final move = tester.widget<Pressable>(find.byKey(const ValueKey('selection-move'))).onTap!;
        move();
        move();
        await pumpAnimations(tester);
        expect(find.byType(BottomSheet), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
        await settle(tester, find.text(ar.moveNotesBodyNoLinks(2)));
        await tester.tap(find.text(ar.cancel).last);
        await pumpAnimations(tester);
        expect(spy.moves, 0);
        expect(selecting(), isTrue);
        expect(find.text(ar.selectedCount(2)), findsOneWidget);
      },
    );
  });

  group('delete', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('fikra-bulk-'));
    tearDown(() => dir.delete(recursive: true));

    fikraTest('two notes go with their files, and only theirs', (tester, db) async {
      phone(tester);
      final paths = await tester.runAsync(() async {
        final made = <String>[];
        for (final name in ['a', 'b', 'c']) {
          final f = File('${dir.path}/$name.pdf');
          await f.writeAsString(name);
          made.add(f.path);
        }
        return made;
      });
      final (_, _, [a, b, c]) = await seedNotes(
        tester,
        db,
        ['A', 'B', 'C'],
        files: {
          0: [paths![0]],
          1: [paths[1]],
          2: [paths[2]],
        },
      );
      await select(tester, [a, b]);
      // Both taps reach the handler (a real second tap may land on the sheet).
      final delete = tester.widget<Pressable>(find.byKey(const ValueKey('selection-delete'))).onTap!;
      delete();
      delete();
      await pumpAnimations(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(ar.deleteNotesTitle(Fmt.notes(ar, 2))), findsOneWidget);
      expect(find.text(ar.deleteNotesBody(2)), findsOneWidget);
      expect(ar.deleteNotesTitle(Fmt.notes(ar, 2)), 'تحذف ملاحظتين؟');
      expect(ar.deleteNotesBody(2), 'الملاحظتين وملفاتهم وروابطهم هيتحذفوا، ومش هتعرف ترجّعهم.');
      final confirm = tester.widget<FikraButton>(find.widgetWithText(FikraButton, ar.delete));
      expect(confirm.style, FikraButtonStyle.danger);
      await tester.tap(find.text(ar.delete).last);
      await settle(tester, find.text(ar.notesDeleted(Fmt.notes(ar, 2))));
      expect(selecting(), isFalse);
      expect(find.text('A'), findsNothing);
      expect(find.text('C'), findsOneWidget);
      Future<bool> exists(String p) async => (await tester.runAsync(() => File(p).exists()))!;
      for (var i = 0; i < 50 && (await exists(paths[0]) || await exists(paths[1])); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
      expect(await exists(paths[0]), isFalse);
      expect(await exists(paths[1]), isFalse);
      expect(await exists(paths[2]), isTrue);
      expect(await pumpFuture(tester, () => db.select(db.notes).get()), hasLength(2)); // C and Work's note
      expect(c.title, 'C');
    });

    late SpyNotes spy;
    fikraTest('a failure midway keeps the rest selected and says so', notesRepository: (db) => spy = SpyNotes(db), (
      tester,
      db,
    ) async {
      phone(tester);
      final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
      spy.failDeleteOf = b.id;
      await select(tester, [c, b, a]);
      await tapAction(tester, 'delete');
      await tester.tap(find.text(ar.delete).last);
      await settle(tester, find.text(ar.deleteNotesFailed));
      // Newest first: C went, B failed, A was not reached.
      expect(spy.deleted, [c.id]);
      await pumpUntil(tester, find.text(ar.selectedCount(2)));
      expect(find.text('C'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
