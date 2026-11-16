import 'dart:ui' show Tristate;

import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/features/links/graph_minimap.dart';
import 'package:fikra/features/shared/group_filter.dart';
import 'package:fikra/features/shared/group_form.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_navigation_fixture.dart';
import 'support/app_harness.dart';

Rect rect(GraphPosition p) => Rect.fromLTWH(p.left, p.top, p.width, p.height);
double? opacityOf(WidgetTester t, Finder f) =>
    t.widgetList<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity))).firstOrNull?.opacity;
Color? iconColor(WidgetTester t, String key) =>
    IconTheme.of(t.element(find.descendant(of: navKey(key), matching: find.byType(Icon)))).color;

void main() {
  for (final ar in [false, true]) {
    fikraTest(
      'chips navigate without filtering; a wide frame shows its start edge at the minimum zoom (ar=$ar)',
      locale: Locale(ar ? 'ar' : 'en'),
      (t, db) async {
        navPhone(t);
        final f = await seedNavigation(t, db, arabic: ar);
        final first = navKey('group-filter-${f.parent.id}'), second = navKey('group-filter-${f.other.id}');
        expect(navKey('group-filter-all'), findsNothing);
        expect(navKey('group-filter-${f.child.id}'), findsNothing);
        expect(
          ar ? t.getCenter(first).dx > t.getCenter(second).dx : t.getCenter(first).dx < t.getCenter(second).dx,
          isTrue,
        );
        await widenParent(t, db, f.parent, f.notes);
        final beforeNodes = graphPaths(t).layout.nodes.keys.toSet();
        await t.tap(first);
        await navPump(t);
        expect(navKey('group-filter-${f.child.id}'), findsOneWidget);
        // Navigation never looks like an active filter, for eyes or TalkBack.
        expect(t.widget<ChoiceTag>(first).selected, isFalse);
        final node = t.getSemantics(first);
        expect(node.label, contains(ar ? 'من غير فلترة' : 'without filtering'));
        expect(node.flagsCollection.isSelected, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);

        // 876 dp wide: cannot fit at 0.5, so the zoom stops at the viewer's
        // minimum and the frame's reading-start edge and header are shown.
        final frame = rect(graphPaths(t).layout.frames.first.bounds);
        expect(viewScale(t), closeTo(0.5, 1e-9));
        expect(navController(t).value.getMaxScaleOnAxis(), closeTo(0.5, 1e-9));
        final viewport = t.getSize(find.byType(InteractiveViewer));
        final shown = sceneOnScreen(t, frame);
        expect(ar ? viewport.width - shown.right : shown.left, closeTo(10, 0.01));
        expect(shown.top, greaterThanOrEqualTo(0));
        expect(shown.top + graphPaths(t).layout.frames.first.header.height * 0.5, lessThan(viewport.height));
        expect(graphPaths(t).layout.nodes.keys.toSet(), beforeNodes);

        // The floor holds for the button and for a pinch.
        await t.tap(find.byIcon(Icons.remove_rounded));
        await t.pump();
        expect(viewScale(t), closeTo(0.5, 1e-9));
        final c = t.getCenter(find.byType(InteractiveViewer));
        final a = await t.startGesture(c - const Offset(80, 0));
        final b = await t.startGesture(c + const Offset(80, 0), pointer: 7);
        for (var i = 0; i < 4; i++) {
          await a.moveBy(const Offset(15, 0));
          await b.moveBy(const Offset(-15, 0));
          await t.pump();
        }
        await a.up();
        await b.up();
        await navPump(t);
        expect(viewScale(t), greaterThanOrEqualTo(0.5 - 1e-9));

        await t.tap(navKey('group-filter-${f.child.id}'));
        await navPump(t);
        expectCentred(t, rect(graphPaths(t).layout.frames.firstWhere((g) => g.group.id == f.child.id).bounds).center);
      },
    );

    fikraTest(
      'no chip row without groups; minimap hidden while the graph fits and exact on its first frame (ar=$ar)',
      locale: Locale(ar ? 'ar' : 'en'),
      (t, db) async {
        navPhone(t);
        await seedGraph(t, db, arabic: ar);
        expect(find.byType(GroupFilterRow), findsNothing);
        // 366 x 444 inside 390 x ~640: nothing to map, from the first frame on.
        expect(navKey('graph-minimap'), findsNothing);
        navController(t).value = Matrix4.diagonal3Values(2, 2, 2);
        await t.pump();
        final r = t.getRect(navKey('graph-minimap'));
        expect(ar ? r.left : 390 - r.right, closeTo(12, 1));
        expect(r.bottom, lessThan(t.getTopLeft(Tabs.finder(Tabs.links)).dy));
        void exact() {
          final viewport = t.getSize(find.byType(InteractiveViewer));
          final painter = t.widget<CustomPaint>(navKey('graph-minimap-viewport')).painter! as GraphMinimapViewport;
          final layout = graphPaths(t).layout;
          final scene = graphViewportRect(navController(t).value, viewport);
          final s = (112 - 8) / layout.width < (84 - 8) / layout.height
              ? (112 - 8) / layout.width
              : (84 - 8) / layout.height;
          expect(painter.rect.height, closeTo(scene.height * s, 1e-6));
          expect(painter.rect.width, closeTo(scene.width * s, 1e-6));
        }

        exact();
        // A shorter viewport with no pan still redraws the rectangle.
        navPhone(t, height: 700);
        await t.pump();
        await t.pump();
        exact();
      },
    );

    fikraTest(
      'RTL stays anchored at the reading start when a fold changes the canvas width; expand restores all (ar=$ar)',
      locale: Locale(ar ? 'ar' : 'en'),
      (t, db) async {
        navPhone(t);
        final f = await seedNavigation(t, db, arabic: ar);
        await widenParent(t, db, f.parent, f.notes);
        await t.tap(navKey('group-filter-${f.other.id}'));
        await navPump(t);
        final before = graphPaths(t).layout;
        final transform = navController(t).value.clone();
        double startEdge() {
          final other = rect(graphPaths(t).layout.frames.firstWhere((g) => g.group.id == f.other.id).bounds);
          final shown = sceneOnScreen(t, other);
          return ar ? shown.right : shown.left;
        }

        final edge = startEdge();
        // The control may be off screen in a wide frame; invoke it directly.
        void toggle() => t.widget<FikraIconButton>(navKey('graph-group-collapse-${f.parent.id}')).onTap!();
        toggle();
        await navPump(t);
        final folded = graphPaths(t).layout;
        expect(folded.frames.first.collapsed, isTrue);
        expect(folded.width, lessThan(before.width));
        expect(startEdge(), closeTo(edge, 0.01));
        toggle();
        await navPump(t);
        final after = graphPaths(t).layout;
        expect(after.frames.first.collapsed, isFalse);
        expect(startEdge(), closeTo(edge, 0.01));
        for (var i = 0; i < 16; i++) {
          expect(navController(t).value.storage[i], closeTo(transform.storage[i], 1e-6));
        }
        expect(after.width, before.width);
        expect(after.positions, before.positions);
        expect(
          after.frames.map((g) => (g.group, g.bounds, g.count)),
          before.frames.map((g) => (g.group, g.bounds, g.count)),
        );
        expect(after.edges.map((e) => e.curves), before.edges.map((e) => e.curves));
      },
    );
  }

  fikraTest('selection mode keeps chips and header controls in place, dimmed and inert', locale: const Locale('en'), (
    t,
    db,
  ) async {
    navPhone(t);
    final f = await seedNavigation(t, db);
    final card = navKey(f.notes[3].id);
    final where = t.getCenter(card);
    final collapse = 'graph-group-collapse-${f.parent.id}', options = 'graph-group-options-${f.parent.id}';
    expect(opacityOf(t, navKey(collapse)), 1);
    expect(iconColor(t, collapse), iconColor(t, options));
    await t.longPress(card);
    await navPump(t);
    expect(t.getCenter(card), where);
    final chip = navKey('group-filter-${f.other.id}');
    expect(opacityOf(t, chip), 0.4);
    expect(opacityOf(t, navKey(collapse)), 0.4);
    expect(opacityOf(t, navKey(options)), 0.4);
    final transform = navController(t).value.clone();
    await t.tap(chip, warnIfMissed: false);
    await navPump(t);
    expect(navController(t).value, transform);
    expect(t.getSemantics(chip).flagsCollection.isEnabled, Tristate.isFalse);
    await t.binding.handlePopRoute();
    await navPump(t);
    expect(t.getCenter(card), where);
    // Focus fade: the parent frame is unrelated to note 4 (linked only to 5), and both
    // controls take its faded icon colour.
    // Move note 4 out from under the minimap in the bottom-end corner.
    navController(t).value = Matrix4.translationValues(0, -200, 0);
    await t.pump();
    await t.tap(navKey(f.notes[4].id));
    await navPump(t);
    expect(iconColor(t, collapse), iconColor(t, options));
    expect(iconColor(t, collapse), t.element(card).colors.textSecondary); // Pearl keeps muted controls readable.
  });

  fikraTest(
    'project switch resets transient state and restores only that project session folds',
    locale: const Locale('en'),
    (t, db) async {
      navPhone(t);
      final f = await seedNavigation(t, db);
      await t.tap(navKey('graph-group-collapse-${f.parent.id}'));
      await navPump(t);
      expect(graphPaths(t).layout.frames.first.collapsed, isTrue);
      final projects = LocalProjectsRepository(db);
      final other = await pumpFuture(t, () async {
        final p = await projects.create('Other project');
        await LocalGroupsRepository(db).create(p.id, 'Other group');
        return p;
      });
      await pumpUntil(t, find.text('Other group'));
      await navPump(t);
      expect(graphPaths(t).layout.frames.single.collapsed, isFalse);
      await graphQuery(t, 'Other');
      await pumpFuture(t, () => projects.setCurrent(f.notes.first.projectId));
      await pumpUntil(t, navKey('graph-group-collapse-${f.parent.id}'));
      await navPump(t);
      expect(navKey('graph-search-field'), findsNothing);
      expect(graphPaths(t).layout.frames.first.collapsed, isTrue);
      await pumpFuture(t, () => projects.setCurrent(other.id));
      await pumpUntil(t, find.text('Other group'));
      await navPump(t);
      expect(graphPaths(t).layout.frames.single.collapsed, isFalse);
    },
  );
}
