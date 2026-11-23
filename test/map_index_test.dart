import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/map_index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';

MapIndex mapOf(List<LibraryNote> notes, List<LibraryLink> links, [List<MapGroup> groups = const []]) {
  final library = deriveLinks('p', notes, links, [
    for (final g in groups) (id: g.id, projectId: 'p', parentId: g.parentId),
  ]);
  return deriveMap((
    library: library,
    adjacency: {
      for (final row in library.browse) row.note.id: [for (final n in row.others) n.id],
    },
    groups: groups,
  ));
}

void main() {
  test('eight clusters includes Others, ungrouped notes, and merged cross-cluster pairs', () {
    final map = mapOf(
      [
        for (var i = 0; i < 10; i++) libraryNote('n$i', group: 'g$i'),
        libraryNote('loose', topic: 'Not a group'),
        libraryNote('child', group: 'child'),
      ],
      [
        libraryLink('a', 'n0', 'n8'),
        libraryLink('reverse', 'n8', 'n0'),
        libraryLink('b', 'n0', 'loose'),
        libraryLink('suggested', 'n1', 'n9', confirmed: false),
      ],
      [
        for (var i = 0; i < 10; i++) (id: 'g$i', name: 'Group $i', parentId: null, color: i % 4),
        (id: 'child', name: 'Child', parentId: 'g0', color: 1),
      ],
    );
    expect(map.clusters, hasLength(8));
    expect(map.clusters.expand((c) => c.notes).toSet(), hasLength(12));
    final others = map.clusters.singleWhere((c) => c.id == 'others');
    expect(others.notes, containsAll(['loose', 'n7', 'n8', 'n9']));
    expect(map.clusterOf['child'], 'group:g0');
    expect(map.edges.single.count, 2);
    expect(map.linkCount, 2);
  });

  test('no groups uses topics, including blank-topic notes and isolated notes', () {
    final map = mapOf([libraryNote('a', topic: 'A'), libraryNote('b', topic: ' '), libraryNote('c', topic: null)], []);
    expect(map.clusters.map((c) => c.id), ['topic:A', 'others']);
    expect(map.clusters.last.notes, ['b', 'c']);
    expect(map.overview().total, 3);
    expect(map.search('Body b').single.id, 'b');
  });

  test('Map search uses the Library Arabic matcher (hamza, word order, prefix)', () {
    final map = mapOf([libraryNote('rag', title: 'إزاي RAG بيشتغل'), libraryNote('other', title: 'ملاحظة تانية')], []);
    expect(map.search('إزاي RAG بيشتغل').map((n) => n.id), ['rag']);
    expect(map.search('ازاي rag').map((n) => n.id), ['rag']);
    expect(map.search('بيشت').map((n) => n.id), ['rag']);
    expect(map.search('RAG إزاي').map((n) => n.id), ['rag']);
    expect(map.search('مفيش'), isEmpty);
    expect(map.search('  '), hasLength(2));
  });

  test('cluster limit ranks by degree and accounts for every omitted note', () {
    final map = mapOf(
      [for (var i = 0; i < 27; i++) libraryNote('n$i')],
      [for (var i = 0; i < 25; i++) libraryLink('e$i', 'n26', 'n$i')],
    );
    final level = map.cluster('topic:Ideas');
    expect(level.nodes.first.id, 'n26');
    expect(level.nodes.where((n) => n.kind == MapNodeKind.note), hasLength(20));
    expect(level.nodes.last, (id: 'more', kind: MapNodeKind.more, count: 7));
    expect(level.total, 27);
    expect(level.omitted, 7);
  });

  test('ego keeps 12 confirmed + 4 suggestions, dedupes and exposes exact +N', () {
    final map = mapOf(
      [libraryNote('centre'), for (var i = 0; i < 25; i++) libraryNote('n$i')],
      [
        for (var i = 0; i < 17; i++) libraryLink('u$i', 'centre', 'n$i'),
        for (var i = 17; i < 25; i++) libraryLink('a$i', 'centre', 'n$i', confirmed: false),
        libraryLink('duplicate', 'n0', 'centre', confirmed: false),
      ],
    );
    final ego = map.ego('centre');
    expect(ego.edges.where((e) => !e.suggested), hasLength(12));
    expect(ego.edges.where((e) => e.suggested), hasLength(4));
    expect(ego.nodes.last.count, 9);
    expect(ego.omitted, 9);
    expect(ego.total, 26);
    expect((ego.confirmed, ego.suggestions), (17, 8));
    expect(ego.nodes, hasLength(18));
  });

  test('grid and radial layouts are deterministic, mirrored, finite and non-overlapping', () {
    final map = mapOf(
      [for (var i = 0; i < 22; i++) libraryNote('n$i')],
      [for (var i = 1; i < 22; i++) libraryLink('l$i', 'n0', 'n$i')],
    );
    for (final ego in [true, false]) {
      final level = ego ? map.ego('n0') : map.cluster('topic:Ideas');
      for (final scale in [1.0, 2.0]) {
        final a = MapLayout.build(level, ego: ego, width: 360, textScale: scale, rtl: false);
        final b = MapLayout.build(level, ego: ego, width: 360, textScale: scale, rtl: false);
        final rtl = MapLayout.build(level, ego: ego, width: 360, textScale: scale, rtl: true);
        expect(a.positions, b.positions);
        expect(a.positions.length, level.nodes.length);
        for (final id in a.positions.keys) {
          expect(a.positions[id]!.x + rtl.positions[id]!.x, closeTo(a.width, .001));
          expect(a.positions[id]!.y, closeTo(rtl.positions[id]!.y, .001));
        }
      }
    }
  });
}
