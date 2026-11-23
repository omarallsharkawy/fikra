import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/connections/map_provider.dart';
import 'package:fikra/features/connections/note_connections_provider.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';

import 'package:fikra/features/connections/links_index.dart';

void main() {
  test('Map caches one revision and invalidates for changed notes or links', () async {
    var library = deriveLinks('p', [libraryNote('a'), libraryNote('b')], [], []);
    final container = ProviderContainer.test(
      overrides: [
        linksLibraryProvider('p').overrideWith((ref) async => library),
        connectionsIndexProvider('p').overrideWith((ref) async => {}),
        groupsOfProjectProvider('p').overrideWith((ref) => Stream.value([])),
      ],
    );
    // Riverpod 3 pauses unlistened providers. Keep the whole chain active.
    final subscription = container.listen(linksMapProvider('p'), (_, _) {});
    addTearDown(subscription.close);
    final first = await container.read(linksMapProvider('p').future);
    expect(identical(first, await container.read(linksMapProvider('p').future)), isTrue);
    library = deriveLinks('p', [libraryNote('a', title: 'Renamed'), libraryNote('b')], [], []);
    container.invalidate(linksLibraryProvider('p'));
    final renamed = await container.read(linksMapProvider('p').future);
    expect(identical(first, renamed), isFalse);
    expect(renamed.notes['a']!.title, 'Renamed');
    library = deriveLinks('p', library.notes.values.toList(), [libraryLink('s', 'a', 'b', confirmed: false)], []);
    container.invalidate(linksLibraryProvider('p'));
    final linked = await container.read(linksMapProvider('p').future);
    expect(identical(renamed, linked), isFalse);
    expect(linked.ego('a').suggestions, 1);
  });
  test('large project Map derivation is isolate-sendable', () async {
    final data = largeLibraryData();
    final library = deriveLinks('p', data.notes, data.links, data.groups);
    final container = ProviderContainer.test(
      overrides: [
        linksLibraryProvider('p').overrideWith((ref) async => library),
        connectionsIndexProvider('p').overrideWith((ref) async => {}),
        groupsOfProjectProvider('p').overrideWith((ref) => Stream.value([])),
      ],
    );
    final subscription = container.listen(linksMapProvider('p'), (_, _) {});
    addTearDown(subscription.close);
    final map = await container.read(linksMapProvider('p').future);
    expect(map.notes, hasLength(5000));
    expect(map.clusters.length, lessThanOrEqualTo(8));
    expect(map.library.suggestions, hasLength(4999));
  });
}
