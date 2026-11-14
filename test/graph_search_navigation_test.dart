import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_navigation_fixture.dart';
import 'support/app_harness.dart';

Rect box(GraphPosition p) => Rect.fromLTWH(p.left, p.top, p.width, p.height);
bool selected(WidgetTester t, String id) =>
    (t.widget(find.descendant(of: navKey('graph-focus-$id'), matching: navKey(id))) as dynamic).selected as bool;

void main() {
  for (final ar in [false, true]) {
    fikraTest(
      'search each kind centres its actual target and focuses only notes (ar=$ar)',
      locale: Locale(ar ? 'ar' : 'en'),
      (t, db) async {
        navPhone(t);
        final f = await seedNavigation(t, db, arabic: ar);
        await graphQuery(t, ar ? 'فكرة التطبيق' : 'APP IDEA');
        expect(find.text(ar ? 'ملاحظة' : 'Note'), findsOneWidget);
        await t.tap(navKey('graph-search-note-${f.notes[0].id}'));
        await navPump(t);
        expect(navKey('graph-search-field'), findsNothing);
        expect(selected(t, f.notes[0].id), isTrue);
        expectCentred(t, box(graphPaths(t).layout.positions[f.notes[0].id]!).center);

        await graphQuery(t, ar ? 'نجرب الفكرة' : 'TRY THE IDEA');
        final result = navKey('graph-search-link-ac');
        expect(find.descendant(of: result, matching: find.textContaining(f.notes[0].title)), findsOneWidget);
        expect(find.descendant(of: result, matching: find.textContaining(f.notes[2].title)), findsOneWidget);
        expect(find.descendant(of: result, matching: find.textContaining(ar ? 'رابط' : 'Link')), findsOneWidget);
        await t.tap(result);
        await navPump(t);
        final e = graphPaths(t).layout.edges.firstWhere((e) => e.link.id == 'ac');
        expectCentred(t, Offset(e.middle.x, e.middle.y));
        expect(selected(t, f.notes[0].id), isTrue);
        expect(navKey('graph-reason-ac'), findsOneWidget);

        await graphQuery(t, f.other.name);
        expect(find.text(ar ? 'مجموعة' : 'Group'), findsOneWidget);
        await t.tap(navKey('graph-search-group-${f.other.id}'));
        await navPump(t);
        final frame = box(graphPaths(t).layout.frames.firstWhere((f2) => f2.group.id == f.other.id).bounds);
        expectCentred(t, frame.center);
        final viewport = t.getSize(find.byType(InteractiveViewer));
        final fitted = MatrixUtils.transformRect(navController(t).value, frame);
        expect((Offset.zero & viewport).contains(fitted.topLeft), isTrue);
        expect((Offset.zero & viewport).contains(fitted.bottomRight), isTrue);
        expect(selected(t, f.notes[0].id), isFalse);
      },
    );
  }

  fikraTest('search expands folded ancestors for a note, link and child group', locale: const Locale('en'), (
    t,
    db,
  ) async {
    navPhone(t);
    final f = await seedNavigation(t, db);
    Future<void> collapse() async {
      navController(t).value = Matrix4.identity();
      await t.pump();
      await t.tap(navKey('graph-group-collapse-${f.parent.id}'));
      await navPump(t);
      expect(graphPaths(t).layout.frames.first.collapsed, isTrue);
      expect(navKey(f.notes[2].id), findsNothing);
    }

    for (final (query, key) in [
      (f.notes[2].title, 'note-${f.notes[2].id}'),
      ('Try the idea', 'link-ac'),
      (f.child.name, 'group-${f.child.id}'),
    ]) {
      await collapse();
      await graphQuery(t, query);
      await t.tap(navKey('graph-search-$key'));
      await navPump(t);
      final layout = graphPaths(t).layout;
      expect(layout.frames.first.collapsed, isFalse);
      expect(navKey('graph-focus-${f.notes[2].id}'), findsOneWidget);
      // The jump uses the expanded layout: right target centred, right selection.
      if (key.startsWith('note')) {
        expectCentred(t, box(layout.positions[f.notes[2].id]!).center);
        expect(selected(t, f.notes[2].id), isTrue);
      } else if (key.startsWith('link')) {
        final e = layout.edges.firstWhere((e) => e.link.id == 'ac');
        expectCentred(t, Offset(e.middle.x, e.middle.y));
        expect(selected(t, f.notes[0].id), isTrue);
        expect(navKey('graph-reason-ac'), findsOneWidget);
      } else {
        expectCentred(t, box(layout.frames.firstWhere((g) => g.group.id == f.child.id).bounds).center);
        expect(selected(t, f.notes[0].id), isFalse);
      }
    }
  });

  fikraTest('hidden search note opens existing note route with limits toast', locale: const Locale('en'), (
    t,
    db,
  ) async {
    navPhone(t);
    final notes = await seedGraph(t, db);
    await pumpFuture(t, () async {
      for (var i = 0; i < 70; i++) {
        await db
            .into(db.notes)
            .insert(
              notes.first.copyWith(
                id: 'limit-$i',
                title: 'Hidden $i',
                status: ProcessingStatus.ready,
                cluster: const Value('One topic'),
              ),
            );
      }
    });
    await navPump(t);
    final l = graphPaths(t).layout;
    final hidden = l.rows.firstWhere((r) => r.cluster == 'One topic').hiddenNotes.last;
    await graphQuery(t, hidden.title);
    await t.tap(navKey('graph-search-note-${hidden.id}'));
    await navPump(t);
    expect(find.text('Hidden by graph limits. Opening the note.'), findsOneWidget);
    expect(find.text(hidden.title), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
  });

  fikraTest(
    'Back closes search first, no-results is plain, selection hides search and map',
    locale: const Locale('en'),
    (t, db) async {
      navPhone(t);
      final notes = await seedGraph(t, db);
      expect(find.byType(SelectionHeader), findsNothing);
      await graphQuery(t, '');
      // Nothing typed yet: no claim that nothing matched.
      expect(find.text('No results'), findsNothing);
      expect(navKey('graph-search-results'), findsNothing);
      // Keystrokes rebuild only the search panel, never the graph screen.
      final builds = LinksScreen.builds;
      for (final text in ['n', 'no', 'not found anywhere']) {
        await t.enterText(find.descendant(of: navKey('graph-search-field'), matching: find.byType(TextField)), text);
        await t.pump();
      }
      expect(LinksScreen.builds, builds);
      expect(find.text('No results'), findsOneWidget);
      expect(navKey('graph-minimap'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is PopScope && !w.canPop), findsWidgets);
      await t.binding.handlePopRoute();
      await navPump(t);
      expect(navKey('graph-search-field'), findsNothing);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await t.longPress(navKey(notes.first.id));
      await t.pump();
      expect(find.byType(SelectionHeader), findsOneWidget);
      expect(navKey('graph-search-open'), findsNothing);
      expect(navKey('graph-minimap'), findsNothing);
    },
  );

  fikraTest(
    'keyboard leaves results scrollable; jump waits for its dismissal; reduced motion is immediate',
    locale: const Locale('en'),
    (t, db) async {
      navPhone(t, height: 700);
      final notes = await seedGraph(t, db);
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await graphQuery(t, 'Try the idea');
      t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await navPump(t);
      final result = navKey('graph-search-link-ac');
      expect(t.getBottomRight(result).dy, lessThanOrEqualTo(400));
      final old = navController(t).value.clone();
      await t.tap(result);
      await t.pump();
      expect(navController(t).value, old);
      t.view.viewInsets = const FakeViewPadding();
      await t.pump();
      await t.pump();
      final e = graphPaths(t).layout.edges.firstWhere((e) => e.link.id == 'ac');
      expectCentred(t, Offset(e.middle.x, e.middle.y));
      expect(selected(t, notes.first.id), isTrue);
    },
  );

  fikraTest(
    'folded groups rename and delete live; capsule and folded lines never multi-select',
    locale: const Locale('en'),
    (t, db) async {
      navPhone(t);
      final f = await seedNavigation(t, db);
      await t.tap(navKey('graph-group-collapse-${f.parent.id}'));
      await navPump(t);
      final frame = navKey('graph-frame-${f.parent.id}');
      expect(t.widget<Semantics>(frame).properties.label, contains('collapsed'));
      final size = t.getSize(navKey('graph-group-collapse-${f.parent.id}'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      final edge = graphPaths(t).layout.edges.firstWhere((e) => graphPaths(t).layout.isFoldedLink(e.link));
      final canvas = t.renderObject<RenderBox>(graphPaint);
      await t.tapAt(canvas.localToGlobal(Offset(edge.middle.x, edge.middle.y)));
      await navPump(t);
      expect(find.byType(BottomSheet), findsNothing);
      await t.longPress(frame);
      await t.pump();
      expect(find.byType(SelectionHeader), findsNothing);
      final repo = LocalGroupsRepository(db);
      await pumpFuture(t, () => repo.rename(f.parent.id, 'Renamed'));
      await navPump(t);
      expect(t.widget<Semantics>(frame).properties.label, contains('Renamed'));
      expect(graphPaths(t).layout.frames.first.collapsed, isTrue);
      await pumpFuture(t, () => repo.delete(f.parent.id));
      await navPump(t);
      expect(frame, findsNothing);
      expect(navKey(f.notes.first.id), findsOneWidget);
      expect(navKey('graph-frame-${f.child.id}'), findsOneWidget);
      expect(find.byType(Pressable), findsWidgets);
    },
  );

  fikraTest('repeated jumps keep one viewport listener: one tick per frame', locale: const Locale('en'), (t, db) async {
    navPhone(t);
    final f = await seedNavigation(t, db);
    for (final g in [f.other, f.parent, f.other]) {
      await t.tap(navKey('group-filter-${g.id}'));
      await navPump(t);
    }
    await t.tap(navKey('group-filter-${f.parent.id}'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    LinksScreen.travelTicks = 0;
    await t.pump(const Duration(milliseconds: 16));
    expect(LinksScreen.travelTicks, 1);
    await navPump(t);
  });
}
