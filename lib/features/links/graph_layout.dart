import 'dart:math' as math;

/// Small, isolate-safe projections. Never include note bodies or attachments.
typedef GraphNote = ({String id, String title, String? cluster, int createdAt, int status});
typedef GraphLink = ({String sourceId, String targetId, String label, double strength});
typedef GraphPosition = ({double left, double top, double width, double height});

class GraphInput {
  GraphInput(this.notes, this.links, {this.rtl = true, this.generalLabel = ''})
    : signature = Object.hash(
        rtl,
        generalLabel,
        notes.length,
        links.length,
        Object.hashAllUnordered(notes),
        Object.hashAllUnordered(links),
      );

  final List<GraphNote> notes;
  final List<GraphLink> links;
  final bool rtl;
  final String generalLabel;

  /// Ignores stream ordering and fields outside the projections. Includes time
  /// (ranking), status, titles, and edge appearance as well as topology.
  final int signature;

  /// Check equality after hashing too: a hash collision must not hide an edit.
  bool sameData(GraphInput other) =>
      signature == other.signature &&
      rtl == other.rtl &&
      generalLabel == other.generalLabel &&
      _sameRecords(notes, other.notes) &&
      _sameRecords(links, other.links);

  static bool _sameRecords<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    // Database streams normally retain their ordering. Avoid building a large
    // frequency map on the common, unchanged-data path.
    var sameOrder = true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        sameOrder = false;
        break;
      }
    }
    if (sameOrder) return true;
    final counts = <T, int>{};
    for (final value in a) {
      counts.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final value in b) {
      final count = counts[value];
      if (count == null) return false;
      if (count == 1) {
        counts.remove(value);
      } else {
        counts[value] = count - 1;
      }
    }
    return counts.isEmpty;
  }
}

class GraphRow {
  const GraphRow({required this.cluster, required this.notes, required this.visible, required this.index});

  final String cluster;
  final List<GraphNote> notes;
  final List<GraphNote> visible;
  final int index;
  int get hiddenCount => notes.length - visible.length;
}

/// Pure layout, with no Flutter, database, or UI objects. Coordinates retain the
/// original graph's geometry; rows begin at the reading start.
class GraphLayout {
  GraphLayout._({
    required this.rtl,
    required this.rows,
    required this.hiddenRows,
    required this.nodes,
    required this.positions,
    required this.links,
    required this.readyCount,
    required this.width,
    required this.height,
  });

  static const nodeWidth = 148.0;
  static const nodeHeight = 54.0;
  static const gapX = 22.0;
  static const rowHeight = 132.0;
  static const padding = 24.0;
  static const smallProjectLimit = 60;

  final bool rtl;
  final List<GraphRow> rows;
  final List<GraphRow> hiddenRows;
  final Map<String, GraphNote> nodes;
  final Map<String, GraphPosition> positions;
  final List<GraphLink> links;
  final int readyCount;
  final double width;
  final double height;

  GraphPosition positionInRow(int row, int column) => (
    left: rtl ? width - padding - (column + 1) * nodeWidth - column * gapX : padding + column * (nodeWidth + gapX),
    top: padding + row * rowHeight + 34,
    width: nodeWidth,
    height: nodeHeight,
  );

  /// Top-level-compatible callback for Flutter's compute().
  static GraphLayout fromInput(GraphInput input) =>
      compute(input.notes, input.links, rtl: input.rtl, generalLabel: input.generalLabel);

  static GraphLayout compute(
    List<GraphNote> notes,
    List<GraphLink> links, {
    bool rtl = true,
    String generalLabel = '',
    int maxNodesPerRow = 12,
    int maxNodes = 240,
    int maxRows = 20,
    int maxEdges = 1000,
    int preserveSmallProjectsUpTo = smallProjectLimit,
  }) {
    assert(maxNodesPerRow > 0 && maxNodes > 0 && maxRows > 0 && maxEdges > 0);
    // ProcessingStatus.ready.index == 1. The input deliberately has no database
    // dependency; every status still participates in the memo signature.
    final ready = notes.where((n) => n.status == 1).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final small = notes.length <= preserveSmallProjectsUpTo;
    final clusters = <String, List<GraphNote>>{};
    for (final note in ready) {
      clusters.putIfAbsent(note.cluster ?? generalLabel, () => []).add(note);
    }
    final ordered = clusters.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    final degree = <String, int>{};
    if (!small) {
      final ids = ready.map((n) => n.id).toSet();
      for (final link in links) {
        if (!ids.contains(link.sourceId) || !ids.contains(link.targetId)) continue;
        degree.update(link.sourceId, (d) => d + 1, ifAbsent: () => 1);
        degree.update(link.targetId, (d) => d + 1, ifAbsent: () => 1);
      }
    }
    final rows = <GraphRow>[];
    final hiddenRows = <GraphRow>[];
    final nodes = <String, GraphNote>{};
    var columns = 1;
    for (final entry in ordered) {
      final rowNotes = entry.value;
      if (!small) {
        rowNotes.sort((a, b) {
          final byDegree = (degree[b.id] ?? 0).compareTo(degree[a.id] ?? 0);
          if (byDegree != 0) return byDegree;
          final byDate = b.createdAt.compareTo(a.createdAt);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
      }
      final count = small
          ? rowNotes.length
          : rows.length >= maxRows
          ? 0
          : math.min(rowNotes.length, math.min(maxNodesPerRow, maxNodes - nodes.length));
      final row = GraphRow(
        cluster: entry.key,
        notes: rowNotes,
        visible: rowNotes.take(count).toList(),
        index: rows.length,
      );
      if (count == 0) {
        hiddenRows.add(row);
        continue;
      }
      rows.add(row);
      columns = math.max(columns, count + (row.hiddenCount > 0 ? 1 : 0));
      for (final note in row.visible) {
        nodes[note.id] = note;
      }
    }
    final visibleLinks = links.where((l) => nodes.containsKey(l.sourceId) && nodes.containsKey(l.targetId)).toList();
    // A dense or duplicate-heavy link set can still be expensive with 240 nodes.
    // Keep the strongest edges, preserving every edge for small projects.
    if (!small && visibleLinks.length > maxEdges) {
      visibleLinks.sort((a, b) => b.strength.compareTo(a.strength));
      visibleLinks.removeRange(maxEdges, visibleLinks.length);
    }
    final layout = GraphLayout._(
      rtl: rtl,
      rows: rows,
      hiddenRows: hiddenRows,
      nodes: nodes,
      positions: {},
      links: visibleLinks,
      readyCount: ready.length,
      width: math.max(360.0, padding * 2 + columns * nodeWidth + (columns - 1) * gapX),
      height: padding * 2 + (rows.length + (hiddenRows.isNotEmpty ? 1 : 0)) * rowHeight,
    );
    for (final row in rows) {
      for (var i = 0; i < row.visible.length; i++) {
        layout.positions[row.visible[i].id] = layout.positionInRow(row.index, i);
      }
    }
    return layout;
  }
}
