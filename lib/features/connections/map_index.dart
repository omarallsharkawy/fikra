import 'dart:math' as math;

import 'links_index.dart';

typedef MapGroup = ({String id, String name, String? parentId, int? color});
typedef MapCluster = ({String id, String? name, int? color, List<String> notes});
typedef MapEdge = ({String a, String b, int count, bool suggested});
typedef MapInput = ({LinksIndex library, Map<String, List<String>> adjacency, List<MapGroup> groups});

/// One immutable source revision. Search, selection and viewport transforms do
/// not derive the project again. Null cluster names are localized as Others.
class MapIndex {
  MapIndex(this.library, this.adjacency, this.clusters, this.clusterOf, this.edges);
  final LinksIndex library;
  final Map<String, List<String>> adjacency;
  final List<MapCluster> clusters;
  final Map<String, String> clusterOf;
  final List<MapEdge> edges;
  Map<String, LibraryNote> get notes => library.notes;
  int get linkCount => adjacency.values.fold(0, (sum, ids) => sum + ids.length) ~/ 2;
  int degree(String id) => adjacency[id]?.length ?? 0;

  List<LibraryNote> search(String query) => library.searchNotes(query);

  MapLevel overview() => MapLevel(
    nodes: [for (final c in clusters) (id: c.id, kind: MapNodeKind.cluster, count: c.notes.length)],
    edges: edges,
    total: notes.length,
    omitted: 0,
    confirmed: linkCount,
    suggestions: library.suggestions.length,
  );

  MapLevel cluster(String id) {
    final ids = clusters.where((c) => c.id == id).firstOrNull?.notes ?? const <String>[];
    final visible = ids.take(20).toSet();
    final members = ids.toSet();
    return MapLevel(
      nodes: [
        for (final n in visible) (id: n, kind: MapNodeKind.note, count: degree(n)),
        if (ids.length > 20) (id: 'more', kind: MapNodeKind.more, count: ids.length - 20),
      ],
      edges: [
        for (final a in visible)
          for (final b in adjacency[a] ?? const <String>[])
            if (visible.contains(b) && a.compareTo(b) < 0) (a: a, b: b, count: 1, suggested: false),
      ],
      total: ids.length,
      omitted: math.max(0, ids.length - 20),
      confirmed:
          ids.fold<int>(0, (n, id) => n + (adjacency[id] ?? const <String>[]).where(members.contains).length) ~/ 2,
      suggestions: 0,
    );
  }

  MapLevel ego(String id) {
    final confirmed = adjacency[id] ?? const <String>[];
    final suggestions = library.suggestionsByNote[id] ?? const <SuggestionEntry>[];
    final linked = confirmed.toSet();
    final suggested = [
      for (final s in suggestions)
        if (!linked.contains(s.a.id == id ? s.b.id : s.a.id)) s.a.id == id ? s.b.id : s.a.id,
    ];
    final omitted = (math.max(0, confirmed.length - 12) + math.max(0, suggested.length - 4)).toInt();
    return MapLevel(
      nodes: [
        if (notes.containsKey(id)) (id: id, kind: MapNodeKind.note, count: degree(id)),
        for (final n in confirmed.take(12)) (id: n, kind: MapNodeKind.note, count: degree(n)),
        for (final n in suggested.take(4)) (id: n, kind: MapNodeKind.suggestion, count: degree(n)),
        if (omitted > 0) (id: 'more', kind: MapNodeKind.more, count: omitted),
      ],
      edges: [
        for (final n in confirmed.take(12)) (a: id, b: n, count: 1, suggested: false),
        for (final n in suggested.take(4)) (a: id, b: n, count: 1, suggested: true),
      ],
      total: confirmed.length + suggested.length + (notes.containsKey(id) ? 1 : 0),
      omitted: omitted,
      confirmed: confirmed.length,
      suggestions: suggested.length,
    );
  }
}

MapIndex deriveMap(MapInput input) {
  final library = input.library, groups = input.groups;
  final byGroup = {for (final g in groups) g.id: g};
  final buckets = <String, List<String>>{
    for (final g in groups)
      if (g.parentId == null) 'group:${g.id}': [],
  };
  final metadata = <String, ({String? name, int? color})>{
    for (final g in groups) 'group:${g.id}': (name: g.name, color: g.color),
  };
  for (final n in library.notes.values) {
    // One source of truth: user group (top-level parent) ?? AI topic ?? others.
    final group = byGroup[n.groupId];
    final String key;
    if (group != null) {
      final parent = byGroup[group.parentId];
      key = 'group:${parent?.id ?? group.id}';
    } else {
      final topic = n.topic?.trim() ?? '';
      key = topic.isEmpty ? 'others' : 'topic:$topic';
      metadata[key] = (name: topic.isEmpty ? null : topic, color: null);
    }
    (buckets[key] ??= []).add(n.id);
  }
  final adjacency = input.adjacency;
  int rank(String a, String b) {
    final degree = (adjacency[b]?.length ?? 0) - (adjacency[a]?.length ?? 0);
    return degree != 0 ? degree : a.compareTo(b);
  }

  final ordered = buckets.keys.where((k) => k != 'others').toList()
    ..sort((a, b) {
      final count = buckets[b]!.length.compareTo(buckets[a]!.length);
      return count != 0 ? count : a.compareTo(b);
    });
  // Eight includes Others: reserve its slot for ungrouped or overflow notes.
  final needsOthers = buckets.containsKey('others') || ordered.length > 8;
  final kept = ordered.take(needsOthers ? 7 : 8).toList();
  final others = [
    for (final k in buckets.keys)
      if (!kept.contains(k)) ...buckets[k]!,
  ];
  final clusters = <MapCluster>[
    for (final k in kept) (id: k, name: metadata[k]?.name, color: metadata[k]?.color, notes: buckets[k]!..sort(rank)),
    if (needsOthers) (id: 'others', name: null, color: null, notes: others..sort(rank)),
  ];
  final clusterOf = {
    for (final c in clusters)
      for (final n in c.notes) n: c.id,
  };
  final counts = <(String, String), int>{};
  for (final e in adjacency.entries) {
    for (final b in e.value) {
      if (e.key.compareTo(b) >= 0) continue;
      final aCluster = clusterOf[e.key], bCluster = clusterOf[b];
      if (aCluster == null || bCluster == null || aCluster == bCluster) continue;
      final key = aCluster.compareTo(bCluster) < 0 ? (aCluster, bCluster) : (bCluster, aCluster);
      counts.update(key, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return MapIndex(library, adjacency, clusters, clusterOf, [
    for (final e in counts.entries) (a: e.key.$1, b: e.key.$2, count: e.value, suggested: false),
  ]);
}

enum MapNodeKind { cluster, note, suggestion, more }

typedef MapNode = ({String id, MapNodeKind kind, int count});

class MapLevel {
  const MapLevel({
    required this.nodes,
    required this.edges,
    required this.total,
    required this.omitted,
    required this.confirmed,
    required this.suggestions,
  });
  final List<MapNode> nodes;
  final List<MapEdge> edges;
  final int total, omitted, confirmed, suggestions;
}

typedef MapPosition = ({double x, double y});

/// Pure, deterministic geometry: no simulation and no per-frame work.
class MapLayout {
  MapLayout(this.positions, this.width, this.height, this.nodeWidth, this.nodeHeight);
  final Map<String, MapPosition> positions;
  final double width, height, nodeWidth, nodeHeight;

  factory MapLayout.build(
    MapLevel level, {
    required bool ego,
    required double width,
    required double textScale,
    required bool rtl,
  }) {
    final w = math.max(320.0, width);
    final nodeWidth = ego ? 148.0 * textScale : (w - 48) / 2;
    final nodeHeight = 76.0 * textScale;
    final positions = <String, MapPosition>{};
    double height, worldWidth;
    if (ego && level.nodes.isNotEmpty) {
      final outerCount = level.nodes.length - 1;
      // Rectangle-aware: neighbours sit at least one node diagonal apart (boxes cannot overlap),
      // and the ring clears the centre box on every side.
      final diagonal = math.sqrt(nodeWidth * nodeWidth + nodeHeight * nodeHeight) + 8;
      final chord = outerCount >= 2 ? diagonal / (2 * math.sin(math.pi / outerCount)) : 0.0;
      final radius = math.max(math.max(nodeWidth + 16, nodeHeight + 24), chord);
      worldWidth = radius * 2 + nodeWidth + 48;
      height = radius * 2 + nodeHeight + 48;
      positions[level.nodes.first.id] = (x: worldWidth / 2, y: height / 2);
      final outer = level.nodes.skip(1).toList();
      for (final (i, n) in outer.indexed) {
        final angle = -math.pi / 2 + (rtl ? -1 : 1) * i * math.pi * 2 / outer.length;
        positions[n.id] = (x: worldWidth / 2 + radius * math.cos(angle), y: height / 2 + radius * math.sin(angle));
      }
    } else {
      worldWidth = w;
      height = math.max(180, ((level.nodes.length + 1) ~/ 2) * (nodeHeight + 28) + 24);
      for (final (i, n) in level.nodes.indexed) {
        final column = rtl ? 1 - i % 2 : i % 2;
        positions[n.id] = (
          x: 16 + nodeWidth / 2 + column * (nodeWidth + 16),
          y: 16 + nodeHeight / 2 + (i ~/ 2) * (nodeHeight + 28),
        );
      }
    }
    return MapLayout(positions, worldWidth, height, nodeWidth, nodeHeight);
  }
}
