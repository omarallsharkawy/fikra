// Phase 7 motion workloads (flying note open/back + scroll with shrinking tab bar),
// called once per forced glass tier by glass_perf_scenario.dart.
import 'dart:math' as math;

import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/note_card.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'links_perf_scenario.dart' show MeasureLinks;

Future<Map<String, Object>> runMotionPerformance(
  WidgetTester tester,
  ProviderContainer container,
  MeasureLinks measure,
) async {
  Future<void> waitFor(bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) throw StateError('Motion workload timed out');
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Finder notesScroll() => find.descendant(
    of: find.byType(NotesScreen),
    matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
  );

  await tester.tap(find.byKey(const ValueKey('nav-0')));
  await waitFor(() => find.byType(NoteCard).hitTestable().evaluate().isNotEmpty);
  final position = tester.state<ScrollableState>(notesScroll()).position;
  position.jumpTo(0);
  await Future<void>.delayed(const Duration(milliseconds: 400));

  final noteOpen = await measure('motion_note_open', () async {
    for (var i = 0; i < 6; i++) {
      final cards = find.byType(NoteCard).hitTestable().evaluate().toList();
      expect(cards, isNotEmpty, reason: 'Stress seed must show visible NoteCards.');
      final cardWidget = cards[i % cards.length].widget;
      await tester.tapAt(tester.getCenter(find.byWidget(cardWidget)));
      await waitFor(() {
        final details = find.byType(NoteDetailsScreen);
        return details.evaluate().isNotEmpty &&
            (ModalRoute.of(tester.element(details))?.animation?.isCompleted ?? false);
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await tester.binding.handlePopRoute();
      await waitFor(() => find.byType(NoteDetailsScreen, skipOffstage: false).evaluate().isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  });

  addTearDown(() => container.read(navBarShrinkEnabledProvider.notifier).setEnabled(false));
  container.read(navBarShrinkEnabledProvider.notifier).setEnabled(true);
  try {
    position.jumpTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final shrinkScroll = await measure('motion_shrink_scroll', () async {
      for (var sweep = 0; sweep < 6; sweep++) {
        await position.animateTo(
          sweep.isEven ? math.min(6000, position.maxScrollExtent) : 0,
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
        );
      }
    });
    position.jumpTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {
      'note_open': {'opens': 6, ...noteOpen},
      'scroll_shrink_bar': {'scroll_duration_seconds': 12, ...shrinkScroll},
    };
  } finally {
    container.read(navBarShrinkEnabledProvider.notifier).setEnabled(false);
  }
}
