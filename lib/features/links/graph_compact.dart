part of 'graph_layout.dart';

GraphLayout _finishGraph(GraphLayout layout) {
  final ports = _assignGraphPorts(layout);
  if (layout.frames.isNotEmpty) layout = _compactFrames(layout, ports);
  layout.labels = _graphLabels(layout);
  layout.edges = _routeGraphEdges(layout, _edgesFromPorts(layout, ports));
  // Finish every retained polyline in the worker, without flattening discarded routes.
  for (final edge in layout.edges) {
    edge._ensurePoints();
  }
  return layout;
}

/// Start at 8 dp, then add only the tallest actual first-row arc + 6 dp.
/// Port ranking is done once; vertical shifts cannot change its logical order.
GraphLayout _compactFrames(GraphLayout layout, List<_GraphPort> ports) {
  final changes = <({double at, double by})>[];
  for (final f in layout.frames) {
    final first = layout.rows.where((r) => r.groupId == f.group.id).firstOrNull;
    if (first == null || first.visible.isEmpty) continue;
    final ids = first.visible.map((n) => n.id).toSet();
    var rise = 0.0;
    for (final p in ports) {
      if (p.sameRow && ids.contains(p.a) && ids.contains(p.b)) rise = math.max(rise, _arcRise(p.start, p.end));
    }
    if (rise + 6 > 8) changes.add((at: layout.positions[first.visible.first.id]!.top, by: rise + 6 - 8));
  }
  double shift(double y) => changes.where((c) => c.at <= y).fold(0.0, (a, c) => a + c.by);
  GraphPosition move(GraphPosition p) => (left: p.left, top: p.top + shift(p.top), width: p.width, height: p.height);
  final rows = [
    for (final r in layout.rows)
      GraphRow(
        cluster: r.cluster,
        notes: r.notes,
        visible: r.visible,
        index: r.index,
        groupId: r.groupId,
        top: r.labelTop + shift(r.labelTop + 34),
        start: r.start,
        canMakeGroup: r.canMakeGroup,
      ),
  ];
  return GraphLayout._(
    rtl: layout.rtl,
    rows: rows,
    hiddenRows: layout.hiddenRows,
    nodes: layout.nodes,
    foldedNotes: layout.foldedNotes,
    positions: {for (final e in layout.positions.entries) e.key: move(e.value)},
    links: layout.links,
    readyCount: layout.readyCount,
    linkCount: layout.linkCount,
    width: layout.width,
    height: layout.height + shift(layout.height),
    suggestedTop: layout.suggestedTop == null ? null : layout.suggestedTop! + shift(layout.suggestedTop!),
    labelSizes: layout.labelSizes,
    suggestedSize: layout.suggestedSize,
    frames: [
      for (final f in layout.frames)
        GraphFrame(
          f.group,
          (
            left: f.bounds.left,
            top: f.bounds.top + shift(f.bounds.top),
            width: f.bounds.width,
            height:
                f.bounds.height +
                changes
                    .where((c) => c.at > f.bounds.top && c.at < f.bounds.top + f.bounds.height)
                    .fold(0.0, (a, c) => a + c.by),
          ),
          f.count,
          f.noteIds,
          headerExtent: f.headerExtent,
          collapsed: f.collapsed,
        ),
    ],
  );
}
