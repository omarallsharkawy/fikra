import 'dart:math' as math;

import '../shared/link_pairs.dart';

part 'graph_geometry.dart';
part 'graph_frames_layout.dart';
part 'graph_input.dart';
part 'graph_labels.dart';
part 'graph_routing.dart';
part 'graph_compact.dart';
part 'graph_ports.dart';
part 'graph_arc_route.dart';
part 'graph_folding.dart';

/// Small, isolate-safe projections. Never include note bodies or attachments.
typedef GraphNote = ({String id, String title, String? cluster, int createdAt, int status});
typedef GraphLink = ({String id, String sourceId, String targetId, String label, double strength, bool isUser});
typedef GraphPosition = ({double left, double top, double width, double height});

class GraphRow {
  const GraphRow({
    required this.cluster,
    required this.notes,
    required this.visible,
    required this.index,
    this.groupId,
    this.top,
    this.start = GraphLayout.padding,
    this.canMakeGroup = false,
  });

  final String cluster;
  final List<GraphNote> notes;
  final List<GraphNote> visible;
  final int index;
  final String? groupId;
  final double? top;
  final double start;
  final bool canMakeGroup;
  double get labelTop => top ?? GraphLayout.padding + index * GraphLayout.rowHeight;
  int get hiddenCount => notes.length - visible.length;
  List<GraphNote> get hiddenNotes => notes.skip(visible.length).toList();
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
    required this.linkCount,
    required this.width,
    required this.height,
    this.frames = const [],
    this.foldedNotes = const {},
    this.suggestedTop,
    this.labelSizes = const {},
    this.suggestedSize = (width: 180, height: 24),
  });

  static const nodeWidth = 148.0;
  static const nodeHeight = 54.0;
  static const gapX = 22.0;
  static const rowHeight = 132.0;
  static const padding = 24.0;
  static const headerHeight = 64.0;
  static const smallProjectLimit = 60;

  final Map<String, GraphTextSize> labelSizes;
  final GraphTextSize suggestedSize;
  late final List<GraphLabel> labels;

  /// Text and controls that connectors must clear, shared by routing, the
  /// painter's mask and tap tests. Cached: the layout is immutable once built.
  /// A capsule is solid; an open frame reserves its whole header strip.
  late final List<GraphPosition> obstacles = [
    for (final f in frames)
      if (f.collapsed)
        (left: f.bounds.left, top: f.bounds.top + 6, width: f.bounds.width, height: f.bounds.height - 12)
      else
        f.header,
    for (final l in labels) l.bounds,
    for (final l in labels)
      if (l.control != null) l.control!,
  ];
  final bool rtl;
  final List<GraphFrame> frames;

  /// Hidden note ID to a capsule endpoint. Capsules are positions, never nodes.
  final Map<String, String> foldedNotes;
  bool isFoldedLink(GraphLink link) => !nodes.containsKey(link.sourceId) || !nodes.containsKey(link.targetId);
  final double? suggestedTop;
  final List<GraphRow> rows;
  final List<GraphRow> hiddenRows;
  final Map<String, GraphNote> nodes;
  final Map<String, GraphPosition> positions;
  final List<GraphLink> links;
  late final List<GraphEdge> edges;
  final int readyCount;
  final int linkCount;
  final double width;
  final double height;

  GraphPosition positionInRow(int row, int column) {
    final data = row < rows.length ? rows[row] : null;
    final start = data?.start ?? padding;
    return (
      left: rtl ? width - start - (column + 1) * nodeWidth - column * gapX : start + column * (nodeWidth + gapX),
      top: (data?.labelTop ?? (padding + row * rowHeight)) + 34,
      width: nodeWidth,
      height: nodeHeight,
    );
  }

  GraphPosition get morePosition =>
      positionInRow(frames.isNotEmpty && hiddenRows.isNotEmpty ? rows.length - 1 : rows.length, 0);

  /// Top-level-compatible callback for Flutter's compute().
  static GraphLayout fromInput(GraphInput input) => compute(
    input.notes,
    input.links,
    rtl: input.rtl,
    generalLabel: input.generalLabel,
    groups: input.groups,
    memberships: input.memberships,
    collapsedGroups: input.collapsedGroups,
    headerExtent: input.headerExtent,
    labelSizes: input.labelSizes,
    suggestedSize: input.suggestedSize,
  );

  static GraphLayout compute(
    List<GraphNote> notes,
    List<GraphLink> links, {
    bool rtl = true,
    String generalLabel = '',
    double headerExtent = headerHeight,
    Map<String, GraphTextSize> labelSizes = const {},
    GraphTextSize suggestedSize = (width: 180, height: 24),
    List<GraphGroup> groups = const [],
    Map<String, String> memberships = const {},
    Set<String> collapsedGroups = const {},
    int maxNodesPerRow = 12,
    int maxNodes = 240,
    int maxRows = 20,
    int maxEdges = 1000,
    int preserveSmallProjectsUpTo = smallProjectLimit,
  }) {
    assert(maxNodesPerRow > 0 && maxNodes > 0 && maxRows > 0 && maxEdges > 0);
    if (groups.isNotEmpty) {
      return _layoutFrames(
        notes,
        links,
        groups,
        memberships,
        collapsedGroups: collapsedGroups,
        rtl: rtl,
        generalLabel: generalLabel,
        headerExtent: headerExtent,
        labelSizes: labelSizes,
        suggestedSize: suggestedSize,
        maxNodesPerRow: maxNodesPerRow,
        maxNodes: maxNodes,
        maxRows: maxRows,
        maxEdges: maxEdges,
        preserveSmallProjectsUpTo: preserveSmallProjectsUpTo,
      );
    }
    // ProcessingStatus.ready.index == 1. The input deliberately has no database
    // dependency; every status still participates in the memo signature.
    final ready = notes.where((n) => n.status == 1).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final small = notes.length <= preserveSmallProjectsUpTo;
    final clusters = <String, List<GraphNote>>{};
    for (final note in ready) {
      clusters.putIfAbsent(note.cluster?.trim().isNotEmpty == true ? note.cluster! : generalLabel, () => []).add(note);
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
        cluster: entry.key.trim().isEmpty ? generalLabel : entry.key,
        canMakeGroup: entry.key.trim().isNotEmpty && rowNotes.every((n) => n.cluster?.trim().isNotEmpty ?? false),
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
    final noteIds = notes.map((n) => n.id).toSet();
    final pairs = uniqueLinkPairs(
      links.where((l) => noteIds.contains(l.sourceId) && noteIds.contains(l.targetId)),
      source: (l) => l.sourceId,
      target: (l) => l.targetId,
      isUser: (l) => l.isUser,
    );
    final visibleLinks = pairs.where((l) => nodes.containsKey(l.sourceId) && nodes.containsKey(l.targetId)).toList();
    // A dense or duplicate-heavy link set can still be expensive with 240 nodes.
    // Keep the strongest edges, preserving every edge for small projects.
    if (!small && visibleLinks.length > maxEdges) {
      visibleLinks.sort((a, b) => b.strength.compareTo(a.strength));
      visibleLinks.removeRange(maxEdges, visibleLinks.length);
    }
    final layout = GraphLayout._(
      rtl: rtl,
      labelSizes: labelSizes,
      suggestedSize: suggestedSize,
      rows: rows,
      hiddenRows: hiddenRows,
      nodes: nodes,
      positions: {},
      links: visibleLinks,
      readyCount: ready.length,
      linkCount: pairs.length,
      width: math.max(360.0, padding * 2 + columns * nodeWidth + (columns - 1) * gapX),
      height: padding * 2 + (rows.length + (hiddenRows.isNotEmpty ? 1 : 0)) * rowHeight,
    );
    for (final row in rows) {
      for (var i = 0; i < row.visible.length; i++) {
        layout.positions[row.visible[i].id] = layout.positionInRow(row.index, i);
      }
    }
    return _finishGraph(layout);
  }
}
