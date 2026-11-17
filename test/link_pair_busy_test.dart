import 'dart:async';

import 'package:fikra/features/connections/link_pair_busy.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';

void main() {
  test('pair lock survives completed write, stale snapshot and isolate refresh; failure unlocks', () async {
    var next = Completer<LinksIndex>();
    final live = deriveLinks(
      'p',
      [libraryNote('a'), libraryNote('b')],
      [libraryLink('ab', 'a', 'b', confirmed: false)],
      [],
    );
    final empty = deriveLinks('p', [libraryNote('a'), libraryNote('b')], [libraryLink('ab', 'a', 'b')], []);
    final container = ProviderContainer(overrides: [linksLibraryProvider('p').overrideWith((ref) => next.future)]);
    addTearDown(container.dispose);
    // Riverpod 3 pauses unlistened providers: keep both explicitly observed.
    final source = container.listen(linksLibraryProvider('p'), (_, _) {});
    final busy = container.listen(linkPairBusyProvider, (_, _) {});
    addTearDown(source.close);
    addTearDown(busy.close);
    next.complete(live);
    await container.read(linksLibraryProvider('p').future);
    final guard = container.read(linkPairBusyProvider.notifier);
    expect(guard.claim('p:a|b', project: 'p', pair: 'a|b'), isTrue);
    guard.finish('p:a|b', success: false);
    expect(container.read(linkPairBusyProvider), isEmpty);
    expect(guard.claim('p:a|b', project: 'p', pair: 'a|b'), isTrue);
    guard.finish('p:a|b', success: true);
    // Success marks the pair done at once, so lists start collapsing it.
    expect(container.read(linkPairBusyProvider), {'p:a|b': true});
    expect(guard.claim('p:a|b', project: 'p', pair: 'a|b'), isFalse);
    next = Completer<LinksIndex>();
    container.invalidate(linksLibraryProvider('p'));
    await container.pump();
    expect(container.read(linkPairBusyProvider), {'p:a|b': true});
    next.complete(empty);
    await container.read(linksLibraryProvider('p').future);
    await container.pump();
    expect(container.read(linkPairBusyProvider), isEmpty);
  });

  test('with no widget listening, the first fresh snapshot ends the lock and a still-live pair unlocks', () async {
    LinksIndex derive(bool suggested) => deriveLinks(
      'p',
      [libraryNote('a'), libraryNote('b')],
      [libraryLink('ab', 'a', 'b', confirmed: !suggested)],
      [],
    );
    var next = Completer<LinksIndex>()..complete(derive(true));
    final container = ProviderContainer(overrides: [linksLibraryProvider('p').overrideWith((ref) => next.future)]);
    addTearDown(container.dispose);
    // Nothing listens to either provider, as when the Links tab is hidden.
    await container.read(linksLibraryProvider('p').future);
    final guard = container.read(linkPairBusyProvider.notifier);
    expect(guard.claim('p:a|b', project: 'p', pair: 'a|b'), isTrue);
    guard.finish('p:a|b', success: true);
    expect(container.read(linkPairBusyProvider), {'p:a|b': true});
    // A newer links emission that still suggests the pair (the write raced a
    // re-analysis): the lock releases and the row shows again.
    next = Completer<LinksIndex>();
    container.invalidate(linksLibraryProvider('p'));
    await container.pump();
    next.complete(derive(true));
    await container.pump();
    await container.pump();
    expect(container.read(linkPairBusyProvider), isEmpty);
    // A failed write unlocks without waiting for any snapshot.
    expect(guard.claim('p:a|b', project: 'p', pair: 'a|b'), isTrue);
    guard.finish('p:a|b', success: false);
    expect(container.read(linkPairBusyProvider), isEmpty);
  });
}
