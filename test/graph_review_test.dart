import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/format.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';

void phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

Future<void> waitGraph(WidgetTester tester, bool Function(GraphLayout) ready) => pumpUntil(
  tester,
  find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.key == const ValueKey('graph-edges') &&
        ready((w.painter as dynamic).paths.layout as GraphLayout),
  ),
);

double contrast(Color fg, Color bg) {
  final a = fg.computeLuminance(), b = bg.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  for (final brightness in [Brightness.dark, Brightness.light]) {
    fikraTest(
      'muted cards and row labels remain readable without opacity layers (${brightness.name})',
      brightness: brightness,
      locale: const Locale('en'),
      (tester, db) async {
        phone(tester);
        final notes = await seedGraph(tester, db);
        final originalLabel = tester.widget<Text>(find.byKey(const ValueKey('graph-cluster-2'))).style!.color!;
        await tester.tap(find.byKey(ValueKey(notes[0].id)));
        await tester.pump();
        for (final note in notes.skip(4)) {
          expect(graphCardDimmed(tester, note.id), isTrue);
          final node = find.byKey(ValueKey('graph-focus-${note.id}'));
          expect(find.descendant(of: node, matching: find.byType(Opacity)), findsNothing);
          final fg = graphCardText(tester, note.id).style!.color!;
          final containers = tester.widgetList<Container>(find.descendant(of: node, matching: find.byType(Container)));
          final bg = (containers.firstWhere((c) => c.decoration is BoxDecoration).decoration as BoxDecoration).color!;
          expect(fg.a, 1);
          expect(contrast(fg, bg), greaterThanOrEqualTo(3));
        }
        final label = tester.widget<Text>(find.byKey(const ValueKey('graph-cluster-2')));
        expect(label.style!.color, isNot(originalLabel));
        expect(contrast(label.style!.color!, tester.element(graphPaint).colors.screen), greaterThanOrEqualTo(3));
      },
    );
  }

  fikraTest('card press animations do not repaint the dedicated edge layer', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    final boundary = find.ancestor(of: graphPaint, matching: find.byType(RepaintBoundary)).first;
    expect(tester.widget(boundary).key, const ValueKey('graph-edges-layer'));
    final dynamic painter = tester.widget<CustomPaint>(graphPaint).painter;
    final before = painter.paintCount as int;
    expect(before, greaterThan(0));
    final touch = await tester.startGesture(tester.getCenter(find.byKey(ValueKey(notes[0].id))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    expect(painter.paintCount, before);
    await touch.cancel();
    await tester.pump(const Duration(milliseconds: 300));
  });

  fikraTest(
    'a stale painted suggestion resolves the current pair and prefers the user row',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final old = graphPaths(tester).layout.edges.firstWhere((e) => e.link.id == 'ab');
      final handler = tester
          .widget<GestureDetector>(find.ancestor(of: graphPaint, matching: find.byType(GestureDetector)).first)
          .onTapUp!;
      await pumpFuture(tester, () async {
        await (db.delete(db.noteLinks)..where((l) => l.id.equals('ab'))).go();
        for (final (id, origin, label) in [
          ('replacement', LinkOrigin.ai, 'new analysis'),
          ('preferred', LinkOrigin.user, 'current user reason'),
        ]) {
          await db
              .into(db.noteLinks)
              .insert(
                NoteLink(
                  id: id,
                  projectId: notes[0].projectId,
                  sourceId: notes[1].id,
                  targetId: notes[0].id,
                  label: label,
                  origin: origin,
                  strength: 0.5,
                  dismissed: false,
                ),
              );
        }
      });
      await waitGraph(tester, (l) => l.links.any((e) => e.id == 'preferred'));
      handler(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: Offset(old.middle.x, old.middle.y),
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(en.editLinkReason), findsOneWidget);
      expect(find.text(en.acceptLink), findsNothing);
      await tester.tap(find.text(en.editLinkReason));
      await pumpUntil(tester, find.byKey(const ValueKey('link-reason-save')));
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'current user reason');
    },
  );

  fikraTest('header counts pairs and ignores legacy reverse and self rows', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    await pumpFuture(tester, () async {
      for (final (id, a, b) in [('reverse', 2, 0), ('self', 0, 0)]) {
        await db
            .into(db.noteLinks)
            .insert(
              NoteLink(
                id: id,
                projectId: notes[0].projectId,
                sourceId: notes[a].id,
                targetId: notes[b].id,
                label: 'legacy',
                strength: 0.4,
                origin: LinkOrigin.ai,
                dismissed: false,
              ),
            );
      }
    });
    await waitGraph(tester, (l) => l.linkCount == 5);
    expect(find.text(en.linksSummary(Fmt.notes(en, 6), Fmt.links(en, 5))), findsOneWidget);
  });

  fikraTest('note rename updates the graph and retains unchanged connector ink', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    final old = graphPaths(tester);
    await pumpFuture(
      tester,
      () => (db.update(
        db.notes,
      )..where((n) => n.id.equals(notes[0].id))).write(const NotesCompanion(title: Value('Renamed idea'))),
    );
    await waitGraph(tester, (l) => l.nodes[notes[0].id]?.title == 'Renamed idea');
    expect(find.text('Renamed idea'), findsOneWidget);
    final next = graphPaths(tester);
    expect(identical(next, old), isFalse);
    expect(next.rebuiltEdges, 0);
    expect(next.sameInk(old), isTrue);
  });

  fikraTest('line taps work in RTL', locale: const Locale('ar'), (tester, db) async {
    phone(tester);
    final notes = await seedGraph(tester, db, arabic: true);
    await tapGraphEdge(tester, 'ab');
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(find.text('${notes[0].title} · ${notes[1].title}'), findsOneWidget);
    expect(find.text(ar.acceptLink), findsOneWidget);
  });

  fikraTest('bottom preview absorbs taps even with a link directly beneath it', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    await tester.tap(find.byKey(ValueKey(notes[0].id)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final preview = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_NodePreview');
    final point = tester.getTopLeft(preview) + const Offset(40, 40);
    final e = graphPaths(tester).layout.edges.firstWhere((e) => e.link.id == 'ef');
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final viewOrigin = tester.getTopLeft(find.byType(InteractiveViewer));
    viewer.transformationController!.value = Matrix4.translationValues(
      point.dx - viewOrigin.dx - e.middle.x,
      point.dy - viewOrigin.dy - e.middle.y,
      0,
    );
    await tester.pump();
    final rendered = tester.renderObject<RenderBox>(graphPaint).localToGlobal(Offset(e.middle.x, e.middle.y));
    expect((rendered - point).distance, lessThan(0.1));
    await tester.tapAt(point);
    await tester.pump();
    expect(find.text(en.linkOptionsTitle), findsNothing);
    expect(preview, findsOneWidget);
  });

  fikraTest('overflow cards and more topics fade but open their own sheets', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    await pumpFuture(
      tester,
      () => db.batch(
        (batch) => batch.insertAll(db.notes, [
          for (var i = 0; i < 286; i++)
            notes[0].copyWith(
              id: 'overflow-$i',
              title: 'Extra $i',
              status: ProcessingStatus.ready,
              cluster: Value(i < 13 ? 'Ideas' : 'Extra cluster ${i ~/ 13}'),
              createdAt: DateTime(2026, 10, 1).add(Duration(minutes: i)),
            ),
        ]),
      ),
    );
    await waitGraph(tester, (l) => l.hiddenRows.isNotEmpty);
    final layout = graphPaths(tester).layout;
    await tester.tap(find.byKey(ValueKey(notes[0].id)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final row = layout.rows.firstWhere((r) => r.cluster == 'Ideas');
    final overflow = find.text('+${row.hiddenCount}');
    final muted = tester.widget<Text>(overflow).style!.color!;
    expect(muted, tester.widget<Text>(find.byKey(const ValueKey('graph-cluster-0'))).style!.color);
    final controller = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    final p = layout.positionInRow(row.index, row.visible.length);
    controller.value = Matrix4.translationValues(100 - p.left, -row.index * GraphLayout.rowHeight, 0);
    await tester.pump();
    await tester.tap(overflow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(en.linkOptionsTitle), findsNothing);
    expect(find.text('Ideas').last, findsOneWidget);
    await tester.tapAt(const Offset(195, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final more = find.text(en.moreTopicsCount(layout.hiddenRows.length));
    expect(tester.widget<Text>(more).style!.color, muted);
    final mp = layout.positionInRow(layout.rows.length, 0);
    controller.value = Matrix4.translationValues(100 - mp.left, 100 - mp.top, 0);
    await tester.pump();
    await tester.tap(more);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(en.moreTopics), findsOneWidget);
    expect(find.text(en.linkOptionsTitle), findsNothing);
  });

  fikraTest(
    'long cluster labels are bounded and reason capsules avoid all titles and labels',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final long = 'A very long cluster name ' * 12;
      await pumpFuture(
        tester,
        () => (db.update(
          db.notes,
        )..where((n) => n.id.isIn([notes[0].id, notes[1].id]))).write(NotesCompanion(cluster: Value(long))),
      );
      await waitGraph(tester, (l) => l.rows.first.cluster == long);
      await tester.tap(find.byKey(ValueKey(notes[0].id)));
      await tester.pump();
      final label = find.byKey(const ValueKey('graph-cluster-0'));
      expect(tester.getSize(label).width, lessThanOrEqualTo(320));
      expect(tester.renderObject<RenderParagraph>(label).didExceedMaxLines, isTrue);
      final obstacles = [
        for (final n in notes) tester.getRect(find.byKey(ValueKey('graph-focus-${n.id}'))),
        for (var i = 0; i < 3; i++) tester.getRect(find.byKey(ValueKey('graph-cluster-$i'))),
      ];
      final capsules = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('graph-reason-'),
      );
      final rects = [
        for (final e in capsules.evaluate()) tester.getRect(find.byElementPredicate((v) => identical(v, e))),
      ];
      for (var i = 0; i < rects.length; i++) {
        expect(obstacles.any(rects[i].overlaps), isFalse);
        for (var j = 0; j < i; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse);
        }
      }
    },
  );
}
