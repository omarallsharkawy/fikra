// Links library and retained graph comparison, called once per forced tier by
// glass_perf_scenario.dart. Uses only the isolated stress seed and real routes.
import 'package:fikra/features/connections/library_cards.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef MeasureLinks = Future<Map<String, Object>> Function(String name, Future<void> Function() action);

Future<Map<String, Object>> runLinksPerformance(WidgetTester tester, MeasureLinks measure) async {
  Future<void> waitFor(bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) throw StateError('Links workload timed out');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Finder scroll() => find.descendant(
    of: find.byType(LinksLibraryScreen),
    matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
  );
  Future<void> flings() async {
    final target = scroll();
    final position = tester.state<ScrollableState>(target).position;
    for (var i = 0; i < 3; i++) {
      for (final delta in [-1300.0, 1300.0]) {
        await tester.fling(target, Offset(0, delta), 3500);
        await waitFor(() => !position.isScrollingNotifier.value);
      }
    }
  }

  await tester.tap(find.byKey(const ValueKey('nav-1')));
  await waitFor(() => find.byKey(const ValueKey('links-segment-0')).hitTestable().evaluate().isNotEmpty);
  await tester.tap(find.byKey(const ValueKey('links-segment-0')));
  await waitFor(() => find.byType(BrowseNoteCard).evaluate().isNotEmpty);
  tester.state<ScrollableState>(scroll()).position.jumpTo(0);
  await Future<void>.delayed(const Duration(milliseconds: 600));
  final browse = await measure('links_browse', flings);

  // Typing: one character at a time at a quick typing pace, past the 180 ms
  // debounce, then clearing (instant). Filters only; no per-query sort.
  final field = find.byKey(const ValueKey('links-search'));
  final search = await measure('links_search', () async {
    const query = 'الشبكات';
    for (var i = 1; i <= query.length; i++) {
      await tester.enterText(field, query.substring(0, i));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.enterText(field, '');
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 600));

  await tester.tap(find.byKey(const ValueKey('links-segment-1')));
  await Future<void>.delayed(const Duration(milliseconds: 500));
  final suggestions = await measure('links_suggestions', flings);
  tester.state<ScrollableState>(scroll()).position.jumpTo(0);
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final actions = await measure('links_actions', () async {
    for (final action in ['accept', 'reject', 'accept', 'reject']) {
      final buttons = tester
          .widgetList<TextButton>(find.byType(TextButton))
          .where((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('$action-'));
      expect(buttons, isNotEmpty, reason: 'Stress seed must keep live suggestions for every tier.');
      final key = buttons.first.key!;
      final target = find.byKey(key);
      await tester.scrollUntilVisible(target, 160, scrollable: scroll());
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.tap(target);
      await waitFor(() => target.evaluate().isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  });

  await tester.tap(find.byKey(const ValueKey('links-open-graph')));
  // The edges painter mounts only once the (isolate) layout is ready; the pan
  // starts then, after the push transition has finished.
  final edges = find.byKey(const ValueKey('graph-edges'));
  await waitFor(
    () => edges.evaluate().isNotEmpty && (ModalRoute.of(tester.element(edges))?.animation?.isCompleted ?? true),
  );
  final graph = await measure('links_graph_pan', () async {
    for (var i = 0; i < 3; i++) {
      for (final delta in [const Offset(-260, -320), const Offset(260, 320)]) {
        await tester.timedDrag(find.byType(InteractiveViewer), delta, const Duration(milliseconds: 900));
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  });
  await tester.tap(find.byType(BackButton));
  await Future<void>.delayed(const Duration(milliseconds: 600));
  await tester.tap(find.byKey(const ValueKey('links-segment-0')));
  await tester.tap(find.byKey(const ValueKey('nav-0')));
  await Future<void>.delayed(const Duration(milliseconds: 400));
  return {'browse': browse, 'search': search, 'suggestions': suggestions, 'pair_actions': actions, 'graph_pan': graph};
}
