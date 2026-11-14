part of 'graph_layout.dart';

/// A logical, top-down packing pass, mirrored only after all widths are known.
/// Empty/limited groups retain their header and (when needed) overflow row.
GraphLayout _layoutFrames(
  List<GraphNote> notes,
  List<GraphLink> links,
  List<GraphGroup> groups,
  Map<String, String> memberships, {
  required Set<String> collapsedGroups,
  required double headerExtent,
  required Map<String, GraphTextSize> labelSizes,
  required GraphTextSize suggestedSize,
  required bool rtl,
  required String generalLabel,
  required int maxNodesPerRow,
  required int maxNodes,
  required int maxRows,
  required int maxEdges,
  required int preserveSmallProjectsUpTo,
}) {
  const pad = GraphLayout.padding, step = GraphLayout.rowHeight;
  final small = notes.length <= preserveSmallProjectsUpTo;
  final ready = notes.where((n) => n.status == 1).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final ids = notes.map((n) => n.id).toSet();
  final pairs = uniqueLinkPairs(
    links.where((l) => ids.contains(l.sourceId) && ids.contains(l.targetId)),
    source: (l) => l.sourceId,
    target: (l) => l.targetId,
    isUser: (l) => l.isUser,
  );
  final degree = <String, int>{};
  if (!small) {
    final readyIds = ready.map((n) => n.id).toSet();
    for (final l in links) {
      if (!readyIds.contains(l.sourceId) || !readyIds.contains(l.targetId)) continue;
      degree.update(l.sourceId, (n) => n + 1, ifAbsent: () => 1);
      degree.update(l.targetId, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  int rank(GraphNote a, GraphNote b) {
    if (small) return a.createdAt.compareTo(b.createdAt);
    final d = (degree[b.id] ?? 0).compareTo(degree[a.id] ?? 0);
    if (d != 0) return d;
    final date = b.createdAt.compareTo(a.createdAt);
    return date != 0 ? date : a.id.compareTo(b.id);
  }

  final ordered = [...groups]
    ..sort((a, b) {
      final p = a.position.compareTo(b.position);
      return p == 0 ? a.id.compareTo(b.id) : p;
    });
  final groupIds = groups.map((g) => g.id).toSet();
  final allIds = <String, Set<String>>{};
  final waiting = <String, List<GraphNote>>{};
  for (final n in notes) {
    final g = memberships[n.id];
    if (g != null) {
      (allIds[g] ??= {}).add(n.id);
      if (n.status != 1) (waiting[g] ??= []).add(n);
    }
  }
  final grouped = <String, List<GraphNote>>{}, topics = <String, List<GraphNote>>{};
  for (final n in ready) {
    final id = memberships[n.id];
    if (groupIds.contains(id)) {
      (grouped[id!] ??= []).add(n);
    } else {
      (topics[n.cluster?.trim().isNotEmpty == true ? n.cluster! : generalLabel] ??= []).add(n);
    }
  }
  final nodes = <String, GraphNote>{}, rows = <GraphRow>[], hidden = <GraphRow>[];
  final frames = <GraphFrame>[];
  var usedRows = 0;
  var canvasEnd = 360.0 - pad;
  double rowWidth(int columns) => columns * GraphLayout.nodeWidth + math.max(0, columns - 1) * GraphLayout.gapX;
  GraphRow row(List<GraphNote> all, int count, String name, String? group, double y, double x) {
    final visible = all.take(count).toList();
    for (final n in visible) {
      nodes[n.id] = n;
    }
    final r = GraphRow(
      cluster: name,
      notes: all,
      visible: visible,
      index: rows.length,
      groupId: group,
      top: y,
      start: x,
      canMakeGroup: group == null && all.isNotEmpty && all.every((n) => n.cluster?.trim().isNotEmpty ?? false),
    );
    rows.add(r);
    canvasEnd = math.max(canvasEnd, x + rowWidth(count + (r.hiddenCount > 0 ? 1 : 0)));
    if (count > 0) usedRows++;
    return r;
  }

  final reached = <String>{};
  final foldedNotes = <String, String>{};
  // An empty frame's width: name, count and both controls fit; a capsule uses it too.
  const minFrameWidth = 240.0;
  GraphFrame frame(GraphGroup g, double y, double x, {bool child = false}) {
    reached.add(g.id);
    if (collapsedGroups.contains(g.id)) {
      final subtree = <String>{g.id};
      final queue = [g.id];
      while (queue.isNotEmpty) {
        final parent = queue.removeLast();
        for (final c in ordered.where((c) => c.parentId == parent)) {
          if (subtree.add(c.id)) queue.add(c.id);
        }
      }
      reached.addAll(subtree);
      final contained = {for (final id in subtree) ...?allIds[id]};
      final f = GraphFrame(
        g,
        (left: x, top: y, width: minFrameWidth, height: headerExtent + 12),
        contained.length,
        contained,
        collapsed: true,
        headerExtent: headerExtent,
      );
      frames.add(f);
      for (final id in contained) {
        foldedNotes[id] = f.endpointId;
      }
      canvasEnd = math.max(canvasEnd, x + f.bounds.width);
      return f;
    }
    final frameIndex = frames.length;
    // Reserve parent order for painting and semantics, fill after children.
    frames.add(GraphFrame(g, (left: x, top: y, width: 0, height: 0), 0, {}));
    var cursor = y + headerExtent + 8 - 34;
    var contentWidth = minFrameWidth;
    final own = [...?grouped[g.id]]..sort(rank);
    var offset = 0;
    while (offset < own.length) {
      final capacity = small ? own.length : math.max(0, math.min(maxNodesPerRow, maxNodes - nodes.length));
      final count = !small && usedRows >= maxRows ? 0 : math.min(own.length - offset, capacity);
      final last =
          count == 0 ||
          offset + count == own.length ||
          (!small && (usedRows + 1 >= maxRows || nodes.length + count >= maxNodes));
      final all = [...own.sublist(offset, last ? own.length : offset + count), if (last) ...?waiting[g.id]];
      final r = row(all, count, g.name, g.id, cursor, x + pad);
      contentWidth = math.max(contentWidth, rowWidth(count + (r.hiddenCount > 0 ? 1 : 0)) + pad * 2);
      cursor += step;
      offset += last ? own.length - offset : count;
    }
    if (own.isEmpty) {
      if (waiting[g.id]?.isNotEmpty ?? false) {
        row(waiting[g.id]!, 0, g.name, g.id, cursor, x + pad);
        contentWidth = math.max(contentWidth, rowWidth(1) + pad * 2);
        cursor += step;
      } else {
        cursor = y + headerExtent + 8;
      }
    }
    final contained = {...?allIds[g.id]};
    if (!child) {
      for (final c in ordered.where((c) => c.parentId == g.id && !reached.contains(c.id))) {
        final f = frame(c, cursor, x + pad, child: true);
        cursor += f.bounds.height + pad;
        contentWidth = math.max(contentWidth, f.bounds.width + pad * 2);
        contained.addAll(f.noteIds);
      }
    }
    final height = own.isEmpty && contained.isEmpty && cursor == y + headerExtent + 8 ? headerExtent + pad : cursor - y;
    final f = GraphFrame(g, (left: x, top: y, width: contentWidth, height: height), contained.length, contained);
    frames[frameIndex] = f;
    canvasEnd = math.max(canvasEnd, x + contentWidth);
    return f;
  }

  var y = pad;
  for (final g in ordered.where((g) => g.parentId == null || !groupIds.contains(g.parentId))) {
    final f = frame(g, y, pad);
    y += f.bounds.height + pad;
  }
  // Malformed deep trees and cycles still get a visible top-level frame.
  for (final g in ordered) {
    if (reached.contains(g.id)) continue;
    final f = frame(g, y, pad);
    y += f.bounds.height + pad;
  }
  final suggestedTop = topics.isEmpty ? null : y;
  if (topics.isNotEmpty) {
    final above = topics.keys.fold(20.0, (a, k) => math.max(a, (labelSizes[k]?.height ?? 20) / 2 - 4));
    y += math.max(48, suggestedSize.height + above + 2);
  }
  final orderedTopics = topics.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final entry in orderedTopics) {
    final all = entry.value..sort(rank);
    final count = small
        ? all.length
        : usedRows >= maxRows
        ? 0
        : math.min(all.length, math.min(maxNodesPerRow, maxNodes - nodes.length));
    if (count == 0) {
      hidden.add(
        GraphRow(
          cluster: entry.key,
          notes: all,
          visible: const [],
          index: rows.length,
          canMakeGroup: all.every((n) => n.cluster?.trim().isNotEmpty ?? false),
        ),
      );
    } else {
      row(all, count, entry.key, null, y, pad);
      y += step;
    }
  }
  // A single aggregate overflow card opens the existing hidden-topic sheet.
  if (hidden.isNotEmpty) {
    row(const [], 0, '', null, y, pad);
    y += step;
  }
  final width = canvasEnd + pad;
  final physicalFrames = [
    for (final f in frames)
      GraphFrame(
        f.group,
        (
          left: rtl ? width - f.bounds.left - f.bounds.width : f.bounds.left,
          top: f.bounds.top,
          width: f.bounds.width,
          height: f.bounds.height,
        ),
        f.count,
        f.noteIds,
        headerExtent: headerExtent,
        collapsed: f.collapsed,
      ),
  ];
  final visibleLinks = foldedNotes.isEmpty
      ? pairs.where((l) => nodes.containsKey(l.sourceId) && nodes.containsKey(l.targetId)).toList()
      : _foldGraphLinks(pairs, ready, nodes, foldedNotes);
  if (!small && visibleLinks.length > maxEdges) {
    visibleLinks.sort((a, b) => b.strength.compareTo(a.strength));
    visibleLinks.removeRange(maxEdges, visibleLinks.length);
  }
  final layout = GraphLayout._(
    rtl: rtl,
    labelSizes: labelSizes,
    suggestedSize: suggestedSize,
    rows: rows,
    hiddenRows: hidden,
    nodes: nodes,
    positions: {},
    links: visibleLinks,
    readyCount: ready.length,
    linkCount: pairs.length,
    width: width,
    height: y + pad,
    frames: physicalFrames,
    foldedNotes: foldedNotes,
    suggestedTop: suggestedTop,
  );
  for (final r in rows) {
    for (final (i, n) in r.visible.indexed) {
      layout.positions[n.id] = layout.positionInRow(r.index, i);
    }
  }
  for (final f in physicalFrames.where((f) => f.collapsed)) {
    layout.positions[f.endpointId] = f.bounds;
  }
  return _finishGraph(layout);
}
