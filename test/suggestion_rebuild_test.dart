import 'dart:async';

import 'package:fikra/app/providers.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/connections/suggestion_card.dart';
import 'package:fikra/features/connections/suggestion_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';
import 'support/selection_fixture.dart';

/// The repository seam controls timing; real pair writes/Undo remain covered by
/// links_library_test and links_groups_moves_test.
class _PairRepository implements LinksRepository {
  final gate = Completer<void>();
  late void Function(bool removed) emit;
  int accepts = 0, rejects = 0, undos = 0;

  Future<PairChange?> _write(String a, String b) async {
    await gate.future;
    emit(true);
    return PairChange(projectId: 'p', a: a, b: b, before: const [], after: const []);
  }

  @override
  Future<PairChange?> acceptPairForUndo(String a, String b) {
    accepts++;
    return _write(a, b);
  }

  @override
  Future<PairChange?> dismissPairForUndo(String a, String b) {
    rejects++;
    return _write(a, b);
  }

  @override
  Future<bool> undoPairChange(PairChange change) async {
    undos++;
    emit(false);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final accept in [true, false]) {
    testWidgets('5000 notes: ${accept ? 'accept' : 'reject'} and Undo preserve unrelated row builds', (tester) async {
      final data = largeLibraryData();
      var index = deriveLinks('p', data.notes, data.links, data.groups);
      final affected = index.suggestions.first;
      final pair = pairKey(affected.a.id, affected.b.id);
      final entries = ValueNotifier(index.suggestions);
      addTearDown(entries.dispose);
      final repo = _PairRepository();
      addTearDown(() {
        if (!repo.gate.isCompleted) repo.gate.complete();
      });
      await host(
        tester,
        ValueListenableBuilder(
          valueListenable: entries,
          builder: (_, rows, _) => CustomScrollView(slivers: [SuggestionSliver(entries: rows)]),
        ),
        overrides: [linksRepoProvider.overrideWithValue(repo), linksLibraryProvider('p').overrideWith((ref) => index)],
      );
      await tester.pump();
      final container = ProviderScope.containerOf(tester.element(find.byType(SuggestionSliver)));
      repo.emit = (removed) {
        index = deriveLinks('p', data.notes, [
          for (final l in data.links)
            if (!removed || pairKey(l.sourceId, l.targetId) != pair) l,
        ], data.groups);
        entries.value = index.suggestions;
        container.invalidate(linksLibraryProvider('p'));
      };
      final mountedRows = find.byType(SuggestionCard).evaluate().toSet();
      expect(mountedRows.length, greaterThan(1));
      var unrelated = 0;
      debugOnRebuildDirtyWidget = (element, _) {
        final w = element.widget;
        if (mountedRows.contains(element) && w is SuggestionCard && pairKey(w.entry.a.id, w.entry.b.id) != pair) {
          unrelated++;
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);
      final button = find.byKey(ValueKey('${accept ? 'accept' : 'reject'}-$pair'));
      final watch = Stopwatch()..start();
      await tester.tap(button);
      await tester.pump();
      final claimBuilds = unrelated;
      expect(accept ? repo.accepts : repo.rejects, 1);
      repo.gate.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pump();
      watch.stop();
      // Timing is diagnostic only; row builds are the deterministic gate.
      // ignore: avoid_print
      print(
        '5000-note ${accept ? 'accept' : 'reject'}: unrelated builds=$unrelated, elapsed=${watch.elapsedMicroseconds}us',
      );
      expect(claimBuilds, 0, reason: 'claim changes only the affected card');
      expect(button, findsNothing);
      expect(unrelated, 0);
      await tester.tap(find.text(arL10n.undo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(repo.undos, 1);
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
      expect(unrelated, 0, reason: 'Undo restores only the affected pair');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
