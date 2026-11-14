part of 'graph_layout.dart';

GraphPosition _inflateBox(GraphPosition p, double d) =>
    (left: p.left - d, top: p.top - d, width: p.width + 2 * d, height: p.height + 2 * d);

/// Open rectangle intersection: touching its boundary is not crossing its ink.
bool graphSegmentIntersectsRect(GraphPoint a, GraphPoint b, GraphPosition r) {
  final right = r.left + r.width, bottom = r.top + r.height;
  if (math.max(a.x, b.x) <= r.left ||
      math.min(a.x, b.x) >= right ||
      math.max(a.y, b.y) <= r.top ||
      math.min(a.y, b.y) >= bottom) {
    return false;
  }
  final dx = b.x - a.x, dy = b.y - a.y;
  var lo = 0.0, hi = 1.0;
  if (dx.abs() > 1e-9) {
    final x1 = (r.left - a.x) / dx, x2 = (right - a.x) / dx;
    lo = math.max(lo, math.min(x1, x2));
    hi = math.min(hi, math.max(x1, x2));
  }
  if (dy.abs() > 1e-9) {
    final y1 = (r.top - a.y) / dy, y2 = (bottom - a.y) / dy;
    lo = math.max(lo, math.min(y1, y2));
    hi = math.min(hi, math.max(y1, y2));
  }
  return hi - lo > 1e-8;
}

bool _edgeHits(GraphEdge e, _RouteBoxes boxes) {
  if (!boxes.index.framed &&
      e.curves.length == 1 &&
      e.end.y - e.start.y > GraphLayout.rowHeight &&
      boxes.sampleHitsCards(e)) {
    return true;
  }
  if (e.curves.length > 1) {
    // A gutter's overall hull covers intervening headers, although each of
    // its three pieces is outside them. Cull pieces before scanning points.
    for (final c in e.curves) {
      final left = math.min(math.min(c.start.x, c.end.x), math.min(c.control1.x, c.control2.x));
      final right = math.max(math.max(c.start.x, c.end.x), math.max(c.control1.x, c.control2.x));
      final top = math.min(math.min(c.start.y, c.end.y), math.min(c.control1.y, c.control2.y));
      final bottom = math.max(math.max(c.start.y, c.end.y), math.max(c.control1.y, c.control2.y));
      for (final r in boxes.index.reserved) {
        if (right <= r.left || left >= r.left + r.width || bottom <= r.top || top >= r.top + r.height) continue;
        final points = e.points;
        for (var i = 1; i < points.length; i++) {
          if (graphSegmentIntersectsRect(points[i - 1], points[i], r)) return true;
        }
      }
    }
  } else {
    // Headers reject most long direct curves without flattening them at all.
    for (final r in boxes.index.reserved) {
      if (e.right < r.left || e.left > r.left + r.width || e.bottom < r.top || e.top > r.top + r.height) continue;
      if (math.min(e.start.y, e.end.y) < r.top &&
          math.max(e.start.y, e.end.y) > r.top + r.height &&
          e.left >= r.left &&
          e.right <= r.left + r.width) {
        return true;
      }
      final points = e.points;
      for (var i = 1; i < points.length; i++) {
        if (graphSegmentIntersectsRect(points[i - 1], points[i], r)) return true;
      }
    }
  }
  return boxes.hitsCards(e);
}

List<GraphEdge> _routeGraphEdges(GraphLayout layout, List<GraphEdge> edges) {
  final reserved = layout.obstacles.map((p) => _inflateBox(p, 2)).toList();
  final index = _RouteIndex(layout, reserved);
  final safe = _safeTopPorts(layout, edges, reserved);
  GraphPoint topPort(GraphPoint p, GraphLink link) => (x: safe[(_endpointId(layout, p, link), p.x)] ?? p.x, y: p.y);
  return [
    for (final original in edges)
      (() {
        final boxes = _RouteBoxes(index, original.link);
        final same = original.start.y == original.end.y;
        final a = same ? topPort(original.start, original.link) : original.start;
        final b = topPort(original.end, original.link);
        final bend = same ? _arcRise(a, b) * 4 / 3 : (b.y - a.y) / 2;
        final e = a == original.start && b == original.end
            ? original
            : GraphEdge(original.link, a, (x: a.x, y: same ? a.y - bend : a.y + bend), (x: b.x, y: b.y - bend), b);
        if (!_edgeHits(e, boxes)) return e;
        if (same) {
          final skirt = _skirtArc(layout, e, boxes);
          if (skirt != null) return skirt;
          final shallow = GraphEdge(e.link, a, (x: a.x, y: a.y - 4), (x: b.x, y: b.y - 4), b);
          if (!_edgeHits(shallow, boxes)) return shallow;
        }
        final routed = _gutterRoute(layout, e, same, boxes);
        // Extreme text scales can cover the port itself. The painter masks all
        // reserved rectangles, so text still wins if no free route exists.
        return routed ?? e;
      })(),
  ];
}

GraphEdge? _gutterRoute(GraphLayout layout, GraphEdge edge, bool same, _RouteBoxes boxes) {
  final a = edge.start, b = edge.end;
  final ap = (x: a.x, y: a.y + (same ? -4 : 4)), bp = (x: b.x, y: b.y - 4);
  final inset = 4.0 + edge.link.id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) % 6) * 2;
  final canvasLanes = layout.rtl ? [layout.width - inset, inset] : [inset, layout.width - inset];
  // Prefer the inner padding strip of the smallest open frame holding both
  // ends: the route stays inside its group instead of crossing every border
  // on the way to the canvas edge. Child frames and rows start a full padding in.
  final home = _commonFrame(layout, a, b);
  final frameLanes = home == null
      ? const <double>[]
      : layout.rtl
      ? [home.bounds.left + home.bounds.width - inset, home.bounds.left + inset]
      : [home.bounds.left + inset, home.bounds.left + home.bounds.width - inset];
  final lanes = [...frameLanes, ...canvasLanes];
  bool clear(GraphPoint x, GraphPoint y) => !boxes.intersects(x, y);
  var top = math.min(a.y, b.y) - 6;
  if (same) {
    for (final r in boxes) {
      if (r.top < a.y &&
          r.top + r.height > a.y - 64 &&
          r.left < math.max(a.x, b.x) &&
          r.left + r.width > math.min(a.x, b.x)) {
        top = math.min(top, r.top - 6);
      }
    }
    top = math.max(2, top);
  }
  if (!same) {
    int nearer(double x, double y) => ((a.x - x).abs() + (b.x - x).abs()).compareTo((a.x - y).abs() + (b.x - y).abs());
    final ordered = [
      ...[...frameLanes]..sort(nearer),
      ...[...canvasLanes]..sort(nearer),
    ];
    for (final lane in ordered) {
      for (final escape in [32.0, 24.0, 12.0, 4.0]) {
        final height = math.min(escape, (b.y - a.y) / 2);
        final enter = (x: lane, y: a.y + height), exit = (x: lane, y: b.y - 4);
        if (!clear(enter, exit) || !clear(ap, enter) || !clear(exit, bp)) continue;
        final curves = <GraphCubic>[
          (start: a, control1: (x: a.x, y: a.y + height / 2), control2: (x: lane, y: a.y + height / 2), end: enter),
          (
            start: enter,
            control1: (x: lane, y: enter.y + (exit.y - enter.y) / 3),
            control2: (x: lane, y: enter.y + 2 * (exit.y - enter.y) / 3),
            end: exit,
          ),
          (start: exit, control1: (x: lane, y: b.y - 2), control2: (x: b.x, y: b.y - 2), end: b),
        ];
        final routed = GraphEdge(edge.link, a, curves.first.control1, curves.last.control2, b, segments: curves);
        if (!_edgeHits(routed, boxes)) return routed;
      }
    }
    return null;
  }
  final candidates = <List<GraphPoint>>[];
  for (final left in lanes) {
    if (!clear(ap, (x: left, y: ap.y))) continue;
    for (final right in lanes) {
      if (!same && left != right) continue;
      if (!clear((x: right, y: bp.y), bp)) continue;
      final path = <GraphPoint>[
        a,
        ap,
        (x: left, y: ap.y),
        if (same) ...[(x: left, y: top), (x: right, y: top)],
        (x: right, y: bp.y),
        bp,
        b,
      ];
      if ([for (var i = 1; i < path.length; i++) clear(path[i - 1], path[i])].every((v) => v)) candidates.add(path);
    }
  }
  double length(List<GraphPoint> p) {
    var d = 0.0;
    for (var i = 1; i < p.length; i++) {
      d += (p[i].x - p[i - 1].x).abs() + (p[i].y - p[i - 1].y).abs();
    }
    return d;
  }

  candidates.sort((a, b) => length(a).compareTo(length(b)));
  for (final path in candidates) {
    for (final radius in [8.0, 1.0, 0.0]) {
      final routed = _roundedRoute(edge.link, path, radius);
      if (!_edgeHits(routed, boxes)) return routed;
    }
  }
  return null;
}

GraphFrame? _commonFrame(GraphLayout layout, GraphPoint a, GraphPoint b) {
  GraphFrame? best;
  bool holds(GraphPosition r, GraphPoint p) =>
      p.x >= r.left - 0.5 && p.x <= r.left + r.width + 0.5 && p.y >= r.top - 0.5 && p.y <= r.top + r.height + 0.5;
  for (final f in layout.frames) {
    if (f.collapsed || !holds(f.bounds, a) || !holds(f.bounds, b)) continue;
    if (best == null || f.bounds.width * f.bounds.height < best.bounds.width * best.bounds.height) best = f;
  }
  return best;
}

GraphEdge _roundedRoute(GraphLink link, List<GraphPoint> raw, double radius) {
  final p = <GraphPoint>[];
  for (final point in raw) {
    if (p.isNotEmpty && p.last == point) continue;
    if (p.length > 1) {
      final a = p[p.length - 2], b = p.last;
      if ((a.x == b.x && b.x == point.x) || (a.y == b.y && b.y == point.y)) p.removeLast();
    }
    p.add(point);
  }
  final curves = <GraphCubic>[];
  GraphPoint mix(GraphPoint a, GraphPoint b, double t) => (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);
  void line(GraphPoint a, GraphPoint b) {
    if (a != b) curves.add((start: a, control1: mix(a, b, 1 / 3), control2: mix(a, b, 2 / 3), end: b));
  }

  var current = p.first;
  for (var i = 1; i < p.length - 1; i++) {
    final a = p[i - 1], b = p[i], c = p[i + 1];
    final before = (b.x - a.x).abs() + (b.y - a.y).abs(), after = (c.x - b.x).abs() + (c.y - b.y).abs();
    final r = math.min(radius, math.min(before, after) / 2);
    final enter = mix(b, a, before == 0 ? 0 : r / before), exit = mix(b, c, after == 0 ? 0 : r / after);
    line(current, enter);
    if (enter != exit) {
      curves.add((start: enter, control1: mix(enter, b, 0.5523), control2: mix(exit, b, 0.5523), end: exit));
    }
    current = exit;
  }
  line(current, p.last);
  return GraphEdge(link, p.first, curves.first.control1, curves.last.control2, p.last, segments: curves);
}
