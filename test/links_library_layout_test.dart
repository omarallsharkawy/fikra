import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/features/connections/library_cards.dart';
import 'package:fikra/features/connections/library_controls.dart';
import 'package:fikra/features/connections/link_pair_busy.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/connections/suggestion_card.dart';
import 'package:fikra/features/connections/suggestion_sliver.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/links_library_data.dart';
import 'support/selection_fixture.dart';

SuggestionEntry suggestion(String id, String a, String b) => (
  a: libraryNote(a, title: 'عنوان ملاحظة طويل جدًا يفضل مقروء وواضح عند تكبير الخط'),
  b: libraryNote(b),
  link: libraryLink(id, a, b, confirmed: false),
);

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('controls and solid rows grow at 3x (${locale.languageCode})', (tester) async {
      final search = TextEditingController();
      addTearDown(search.dispose);
      final e = suggestion('ab', 'a', 'b');
      final heights = <double>[];
      for (final scale in [1.0, 3.0]) {
        await host(
          tester,
          Column(
            children: [
              LibraryControls(
                search: search,
                onSearch: (_) {},
                suggestions: 3,
                segment: 1,
                onSegment: (_) {},
                sort: LinksSort.newest,
                onSort: (_) {},
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          BrowseNoteCard(entry: (note: e.a, others: [e.b])),
                          SuggestionCard(entry: e),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          locale: locale,
          scale: scale,
          overrides: [glassTierProvider(false).overrideWith((ref) => GlassTier.solid)],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        heights.add(tester.getSize(find.byType(BrowseNoteCard)).height);
      }
      expect(heights[1], greaterThan(heights[0]));
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final reduced in [false, true]) {
    testWidgets('only removed suggestion collapses; reduced motion=$reduced', (tester) async {
      final a = suggestion('ab', 'a', 'b'), b = suggestion('cd', 'c', 'd');
      final entries = ValueNotifier([a, b]);
      addTearDown(entries.dispose);
      await host(
        tester,
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: ValueListenableBuilder(
            valueListenable: entries,
            builder: (_, value, _) => CustomScrollView(slivers: [SuggestionSliver(entries: value)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final stableFinder = find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == 'cd');
      final stable = tester.state(stableFinder);
      final stableWidget = tester.widget(stableFinder);
      entries.value = [b];
      await tester.pump();
      if (reduced) {
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == 'ab'), findsNothing);
      } else {
        await tester.pump(const Duration(milliseconds: 110));
        final leaving = find.ancestor(
          of: find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == 'ab'),
          matching: find.byType(FadeTransition),
        );
        final opacity = tester.widget<FadeTransition>(leaving).opacity.value;
        expect(opacity, greaterThan(0));
        expect(opacity, lessThan(1));
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == 'ab'), findsNothing);
      }
      expect(tester.state(stableFinder), same(stable));
      expect(tester.widget(stableFinder), same(stableWidget), reason: 'unrelated rows do not rebuild');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('fresh snapshot unlock with stale parent entries keeps the original collapse deadline', (tester) async {
    final a = suggestion('ab', 'a', 'b'), b = suggestion('cd', 'c', 'd');
    LinksIndex snapshot(bool removed) => deriveLinks('p', [a.a, a.b, b.a, b.b], [if (!removed) a.link, b.link], []);
    var next = Completer<LinksIndex>()..complete(snapshot(false));
    await host(
      tester,
      CustomScrollView(
        slivers: [
          SuggestionSliver(entries: [a, b]),
        ],
      ),
      overrides: [linksLibraryProvider('p').overrideWith((ref) => next.future)],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(SuggestionSliver)));
    final source = container.listen(linksLibraryProvider('p'), (_, _) {});
    addTearDown(source.close);
    await tester.pump();
    final guard = container.read(linkPairBusyProvider.notifier);
    guard.claim('p:a|b', project: 'p', pair: 'a|b');
    guard.finish('p:a|b', success: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    next = Completer<LinksIndex>()..complete(snapshot(true));
    container.invalidate(linksLibraryProvider('p'));
    await tester.pump();
    await tester.pump();
    expect(container.read(linkPairBusyProvider), isEmpty);
    // Parent deliberately retains its pre-write list while the lock releases.
    final leaving = find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == 'ab');
    final fade = find.ancestor(of: leaving, matching: find.byType(FadeTransition));
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 120));
    expect(leaving, findsNothing, reason: 'unlock must not restart or cancel the original collapse');
    await tester.pumpWidget(const SizedBox());
  });

  for (final locked in [false, true]) {
    testWidgets('two removals within 220 ms keep the first row in place (${locked ? 'accept lock' : 'new list'})', (
      tester,
    ) async {
      final rows = [
        for (final id in ['a', 'b', 'c', 'd']) suggestion('$id$id', id, '${id}2'),
      ];
      final entries = ValueNotifier(rows);
      addTearDown(entries.dispose);
      await host(
        tester,
        ValueListenableBuilder(
          valueListenable: entries,
          builder: (_, value, _) => CustomScrollView(slivers: [SuggestionSliver(entries: value)]),
        ),
        // The derived snapshot never arrives: only the lock can collapse a row.
        overrides: [linksLibraryProvider('p').overrideWith((ref) => Completer<LinksIndex>().future)],
      );
      await tester.pumpAndSettle();
      Finder card(String id) => find.byWidgetPredicate((w) => w is SuggestionCard && w.entry.link.id == id);
      List<String> order() => [
        for (final w in tester.widgetList<SuggestionCard>(find.byType(SuggestionCard))) w.entry.link.id,
      ];
      final top = tester.getTopLeft(card('bb')).dy;
      final guard = ProviderScope.containerOf(tester.element(find.byType(SuggestionSliver)))
          .read(linkPairBusyProvider.notifier);
      for (final id in ['b', 'c']) {
        if (locked) {
          final pair = pairKey(id, '${id}2');
          guard.claim('p:$pair', project: 'p', pair: pair);
          guard.finish('p:$pair', success: true);
        } else {
          entries.value = [
            for (final e in entries.value)
              if (e.a.id != id) e,
          ];
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final opacity = tester
            .widget<FadeTransition>(find.ancestor(of: card('$id$id'), matching: find.byType(FadeTransition)))
            .opacity
            .value;
        expect(opacity, lessThan(1), reason: 'collapse starts at once');
        expect(order(), ['aa', 'bb', 'cc', 'dd']);
        expect(tester.getTopLeft(card('bb')).dy, top);
      }
      if (locked) {
        // The re-derived list arrives mid-collapse; nothing moves.
        entries.value = [rows[0], rows[3]];
        await tester.pump();
        expect(order(), ['aa', 'bb', 'cc', 'dd']);
        expect(tester.getTopLeft(card('bb')).dy, top);
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(order(), ['aa', 'dd']);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
