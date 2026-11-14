import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  fikraTest(
    'graph user-line options name both notes, edit reason and remove after confirmation',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      await tapGraphEdge(tester, 'ac');
      expect(find.text('${notes[0].title} · ${notes[2].title}'), findsOneWidget);
      expect(find.text(en.editLinkReason), findsOneWidget);
      expect(find.text(en.acceptLink), findsNothing);
      await tester.tap(find.text(en.editLinkReason));
      await pumpUntil(tester, find.byKey(const ValueKey('link-reason-save')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('link-reason')), matching: find.byType(TextField)),
        'Changed from graph',
      );
      await tester.tap(find.byKey(const ValueKey('link-reason-save')));
      await pumpFuture(tester, () async {
        await db
            .select(db.noteLinks)
            .watch()
            .firstWhere((rows) => rows.any((l) => l.id == 'ac' && l.label == 'Changed from graph'));
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(graphPaths(tester).layout.links.firstWhere((l) => l.id == 'ac').label, 'Changed from graph');
      await tapGraphEdge(tester, 'ac');
      await tester.tap(find.text(en.removeLink));
      await pumpUntil(tester, find.text(en.removeLinkTitle));
      await tester.pump(const Duration(milliseconds: 500));
      expect(graphPaths(tester).layout.links.any((l) => l.id == 'ac'), isTrue);
      await tester.tap(find.text(en.removeLinkConfirm));
      await pumpFuture(
        tester,
        () => db.select(db.noteLinks).watch().firstWhere((rows) => rows.any((l) => l.id == 'ac' && l.dismissed)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(graphPaths(tester).layout.links.any((l) => l.id == 'ac'), isFalse);
    },
  );

  fikraTest('graph suggestion-line options accept and reject and update the graph', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    final beforeAccept = graphPaths(tester);
    await tapGraphEdge(tester, 'ab');
    expect(find.text('${notes[0].title} · ${notes[1].title}'), findsOneWidget);
    expect(find.text(en.linkSuggestedTag), findsOneWidget);
    expect(find.text(en.removeLink), findsNothing);
    await tester.tap(find.text(en.acceptLink));
    await pumpFuture(
      tester,
      () => db
          .select(db.noteLinks)
          .watch()
          .firstWhere((rows) => rows.any((l) => l.id == 'ab' && l.origin == LinkOrigin.user)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(graphPaths(tester).layout.links.firstWhere((l) => l.id == 'ab').isUser, isTrue);
    expect(identical(beforeAccept, graphPaths(tester)), isFalse);
    expect(graphPaths(tester).edges.firstWhere((e) => e.geometry.link.id == 'ab').dashPoints, isEmpty);
    await tapGraphEdge(tester, 'ab');
    expect(find.text(en.editLinkReason), findsOneWidget);
    await tester.tapAt(const Offset(195, 10));
    await tester.pump(const Duration(milliseconds: 500));
    await tapGraphEdge(tester, 'ad');
    await tester.tap(find.text(en.rejectLink));
    await pumpFuture(
      tester,
      () => db.select(db.noteLinks).watch().firstWhere((rows) => rows.any((l) => l.id == 'ad' && l.dismissed)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(graphPaths(tester).layout.links.any((l) => l.id == 'ad'), isFalse);
  });

  fikraTest(
    'selecting a card focuses neighbours, limits capsules, exposes accessible link actions and reuses paths',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      try {
        final notes = await seedGraph(tester, db);
        final cache = graphPaths(tester);
        final initial = tester.widget<CustomPaint>(graphPaint).painter!;
        final ink = _GraphInk();
        initial.paint(ink, Size.zero);
        expect(ink.dots, hasLength(10));
        for (final dot in ink.dots) {
          expect(dot.$1, 3);
          expect(dot.$2, PaintingStyle.fill);
        }
        final palette = tester.element(graphPaint).colors;
        for (var i = 0; i < cache.edges.length; i++) {
          final edge = cache.edges[i];
          final stroke = ink.strokes[i];
          expect(stroke.$2.strokeWidth, closeTo(edge.geometry.link.isUser ? 2 : 1.2, 1e-6));
          expect(
            stroke.$2.color.toARGB32(),
            (edge.geometry.link.isUser ? palette.accent : palette.graphEdge.withValues(alpha: 0.55)).toARGB32(),
          );
          expect(identical(stroke.$1, edge.geometry.link.isUser ? edge.path : edge.dashPoints), isTrue);
          if (!edge.geometry.link.isUser) expect(edge.dashPoints.length, greaterThan(4));
        }
        expect(
          find.byWidgetPredicate(
            (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('graph-reason-'),
          ),
          findsNothing,
        );
        await tester.tap(find.byKey(ValueKey(notes[0].id)));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(en.linkOptionsTitle), findsNothing); // card wins over nearby lines
        expect(identical(graphPaths(tester), cache), isTrue);
        for (var i = 0; i < notes.length; i++) {
          expect(graphCardDimmed(tester, notes[i].id), i >= 4);
        }
        expect(find.byKey(const ValueKey('graph-reason-ac')), findsOneWidget);
        expect(find.byKey(const ValueKey('graph-reason-ab')), findsOneWidget);
        final label = find.descendant(of: find.byKey(const ValueKey('graph-reason-ab')), matching: find.byType(Text));
        expect(tester.getSize(label).width, lessThanOrEqualTo(160));
        expect(tester.widget<Text>(label).maxLines, 1);
        expect(tester.widget<Text>(label).overflow, TextOverflow.ellipsis);
        for (final id in ['ad', 'cd', 'ef']) {
          expect(find.byKey(ValueKey('graph-reason-$id')), findsNothing);
        }
        final painter = tester.widget<CustomPaint>(graphPaint).painter!;
        expect(painter.shouldRepaint(initial), isTrue);
        // The selected node has one custom action per linked note, including the
        // unlabelled suggestion. They open the same sheet as a line tap.
        final node = tester.getSemantics(
          find.descendant(
            of: find.byKey(ValueKey('graph-focus-${notes[0].id}')),
            matching: find.byKey(ValueKey(notes[0].id)),
          ),
        );
        final data = node.getSemanticsData();
        expect(data.customSemanticsActionIds, hasLength(3));
        final id = data.customSemanticsActionIds!.firstWhere(
          (id) => CustomSemanticsAction.getAction(id)!.label!.contains(notes[1].title),
        );
        expect(CustomSemanticsAction.getAction(id)!.label, contains(notes[1].title));
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.customAction,
          id,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(en.linkOptionsTitle), findsOneWidget);
        await tester.tapAt(const Offset(195, 10));
        await tester.pump(const Duration(milliseconds: 500));
        final beforeZoom = tester.widget<CustomPaint>(graphPaint).painter!;
        await tester.tap(find.bySemanticsLabel(en.zoomIn));
        await tester.pump(const Duration(milliseconds: 500));
        expect(identical(graphPaths(tester), cache), isTrue);
        expect(tester.widget<CustomPaint>(graphPaint).painter!.shouldRepaint(beforeZoom), isFalse);
        // Preserve token colours and exact stroke-style inputs.
        final dynamic configured = tester.widget<CustomPaint>(graphPaint).painter;
        expect(configured.accent, tester.element(graphPaint).colors.accent);
        expect(configured.dimmed, {'cd', 'ef'});
        final focusedInk = _GraphInk();
        (configured as CustomPainter).paint(focusedInk, Size.zero);
        final unrelatedIndex = cache.edges.indexWhere((e) => e.geometry.link.id == 'ef');
        expect(
          focusedInk.strokes[unrelatedIndex].$2.color.toARGB32(),
          palette.accent.withValues(alpha: 0.16).toARGB32(),
        );
        final neighboursIndex = cache.edges.indexWhere((e) => e.geometry.link.id == 'cd');
        expect(
          focusedInk.strokes[neighboursIndex].$2.color.toARGB32(),
          palette.accent.withValues(alpha: 0.16).toARGB32(),
        );
      } finally {
        semantics.dispose();
      }
    },
  );
  fikraTest(
    'screen-space line taps after real zoom-out and panning preserve card priority and cached paths',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final cache = graphPaths(tester);
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final controller = viewer.transformationController!;
      final original = controller.value.clone();
      await tester.drag(graphPaint, const Offset(40, -30));
      await tester.pump();
      expect(controller.value, isNot(original));
      expect(find.text(en.linkOptionsTitle), findsNothing);
      expect(identical(graphPaths(tester), cache), isTrue);
      await tester.tap(find.byIcon(Icons.center_focus_strong_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      final edge = cache.layout.edges.firstWhere((e) => e.link.id == 'ef');
      final box = tester.renderObject<RenderBox>(graphPaint);
      expect(controller.value.entry(0, 0), closeTo(0.8, 1e-9));
      // Zoom scales z too, so the viewer's getMaxScaleOnAxis clamp reads 0.8.
      expect(controller.value.entry(2, 2), closeTo(0.8, 1e-9));
      // A matrix whose z differs from XY must still hit-test with the XY scale.
      controller.value = controller.value.clone()..setEntry(2, 2, 1);
      await tester.pump();
      // 21.5 screen dp = 26.875 logical dp: a wrong Z-based scale misses.
      final point = box.localToGlobal(Offset(edge.middle.x, edge.middle.y)) - const Offset(0, 21.5);
      await tester.tapAt(point);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('${notes[4].title} · ${notes[5].title}'), findsOneWidget);
      await tester.tapAt(const Offset(195, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      controller.value = Matrix4.identity();
      await tester.pump();
      await tester.tapAt(box.localToGlobal(Offset(edge.middle.x, edge.middle.y)) - const Offset(0, 30));
      await tester.pump();
      expect(find.text(en.linkOptionsTitle), findsNothing);
      final card = cache.layout.positions[notes[4].id]!;
      await tester.tapAt(box.localToGlobal(Offset(card.left + card.width / 2, card.top + 1)));
      await tester.pump();
      expect(find.text(en.linkOptionsTitle), findsNothing);
      expect(graphCardDimmed(tester, notes[0].id), isTrue);
      expect(identical(graphPaths(tester), cache), isTrue);
    },
  );
  fikraTest('same-title neighbours retain separate accessible link actions', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    try {
      final notes = await seedGraph(tester, db);
      await pumpFuture(
        tester,
        () => (db.update(
          db.notes,
        )..where((n) => n.id.isIn([notes[1].id, notes[2].id]))).write(const NotesCompanion(title: Value('Same name'))),
      );
      await pumpUntil(tester, find.text('Same name'));
      await tester.tap(find.byKey(ValueKey(notes[0].id)));
      await tester.pump();
      final node = tester.getSemantics(
        find.descendant(
          of: find.byKey(ValueKey('graph-focus-${notes[0].id}')),
          matching: find.byKey(ValueKey(notes[0].id)),
        ),
      );
      final actions = node.getSemanticsData().customSemanticsActionIds!;
      expect(actions, hasLength(3));
      final labels = actions.map((id) => CustomSemanticsAction.getAction(id)!.label).toList();
      expect(labels, contains('${en.linkOptionsA11y('Same name')} (1)'));
      expect(labels, contains('${en.linkOptionsA11y('Same name')} (2)'));
    } finally {
      handle.dispose();
    }
  });
}

/// Snapshot mutable Paint values at the draw call; retained paths must be the
/// cache's exact objects, not reconstructed lookalikes.
class _GraphInk extends TestRecordingCanvas {
  final strokes = <(Object, Paint)>[];
  final dots = <(double, PaintingStyle)>[];
  @override
  void drawPath(Path path, Paint paint) => strokes.add((path, Paint.from(paint)));
  @override
  void drawRawPoints(PointMode mode, Float32List points, Paint paint) {
    expect(mode, PointMode.lines);
    strokes.add((points, Paint.from(paint)));
  }

  @override
  void drawCircle(Offset centre, double radius, Paint paint) => dots.add((radius, paint.style));
}
