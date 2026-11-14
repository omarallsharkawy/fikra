part of 'graph_layout.dart';

typedef GraphPoint = ({double x, double y});

/// A cubic in physical canvas coordinates, assigned in logical reading order.
/// Its polyline and control-hull bounds are built once, never during a gesture.
typedef GraphCubic = ({GraphPoint start, GraphPoint control1, GraphPoint control2, GraphPoint end});

class GraphEdge {
  GraphEdge(this.link, this.start, this.control1, this.control2, this.end, {List<GraphCubic>? segments}) {
    curves = segments ?? [(start: start, control1: control1, control2: control2, end: end)];
    left = math.min(math.min(start.x, end.x), math.min(control1.x, control2.x));
    right = math.max(math.max(start.x, end.x), math.max(control1.x, control2.x));
    top = math.min(math.min(start.y, end.y), math.min(control1.y, control2.y));
    bottom = math.max(math.max(start.y, end.y), math.max(control1.y, control2.y));
    for (final c in curves) {
      left = math.min(left, math.min(math.min(c.start.x, c.end.x), math.min(c.control1.x, c.control2.x)));
      right = math.max(right, math.max(math.max(c.start.x, c.end.x), math.max(c.control1.x, c.control2.x)));
      top = math.min(top, math.min(math.min(c.start.y, c.end.y), math.min(c.control1.y, c.control2.y)));
      bottom = math.max(bottom, math.max(math.max(c.start.y, c.end.y), math.max(c.control1.y, c.control2.y)));
    }
  }

  final GraphLink link;
  final GraphPoint start, control1, control2, end;
  List<GraphPoint>? _points;
  List<GraphPoint> get points {
    _ensurePoints();
    return _points!;
  }

  void _ensurePoints() {
    if (_points != null) return;
    _points = [start];
    for (final c in curves) {
      _flatten(c.start, c.control1, c.control2, c.end, 0);
    }
  }

  late final List<GraphCubic> curves;
  late double left, right, top, bottom;

  GraphPoint get middle => pointAt(0.5);

  GraphPoint pointAt(double t) {
    final index = math.min(curves.length - 1, (t * curves.length).floor());
    t = t == 1 ? 1 : t * curves.length - index;
    final c = curves[index];
    final start = c.start, control1 = c.control1, control2 = c.control2, end = c.end;
    final u = 1 - t;
    return (
      x: u * u * u * start.x + 3 * u * u * t * control1.x + 3 * u * t * t * control2.x + t * t * t * end.x,
      y: u * u * u * start.y + 3 * u * u * t * control1.y + 3 * u * t * t * control2.y + t * t * t * end.y,
    );
  }

  void _flatten(GraphPoint a, GraphPoint b, GraphPoint c, GraphPoint d, int depth) {
    // Subdivision bounds curve error to 0.2 logical pixels (0.5 at max zoom).
    if (depth == 12 || math.max(_distanceSquared(b, a, d), _distanceSquared(c, a, d)) <= 0.04) {
      _points!.add(d);
      return;
    }
    GraphPoint mid(GraphPoint p, GraphPoint q) => (x: (p.x + q.x) / 2, y: (p.y + q.y) / 2);
    final ab = mid(a, b), bc = mid(b, c), cd = mid(c, d);
    final abc = mid(ab, bc), bcd = mid(bc, cd), m = mid(abc, bcd);
    _flatten(a, ab, abc, m, depth + 1);
    _flatten(m, bcd, cd, d, depth + 1);
  }
}

double _distanceSquared(GraphPoint p, GraphPoint a, GraphPoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final length = dx * dx + dy * dy;
  final t = length == 0 ? 0.0 : (((p.x - a.x) * dx + (p.y - a.y) * dy) / length).clamp(0.0, 1.0);
  final x = p.x - a.x - t * dx, y = p.y - a.y - t * dy;
  return x * x + y * y;
}

typedef _GraphPort = ({String a, String b, bool sameRow, GraphPoint start, GraphPoint end});

List<_GraphPort> _assignGraphPorts(GraphLayout layout) {
  double logicalX(GraphPosition p) => layout.rtl ? layout.width - p.left - p.width : p.left;
  final ports = <(String, bool), List<({int edge, String other})>>{};
  final endpoints = <({String a, String b, bool sameRow})>[];
  for (final (i, link) in layout.links.indexed) {
    var a = link.sourceId, b = link.targetId;
    final ap = layout.positions[a]!, bp = layout.positions[b]!;
    final sameRow = ap.top == bp.top;
    // Upper to lower; same-row edges follow reading order, irrespective of
    // stored source/target direction. Mirroring never changes port ranks.
    if (ap.top > bp.top || (sameRow && logicalX(ap) > logicalX(bp))) {
      final swap = a;
      a = b;
      b = swap;
    }
    endpoints.add((a: a, b: b, sameRow: sameRow));
    ports.putIfAbsent((a, sameRow), () => []).add((edge: i, other: b));
    ports.putIfAbsent((b, true), () => []).add((edge: i, other: a));
  }
  final assigned = <(int, String), GraphPoint>{};
  for (final entry in ports.entries) {
    final (id, isTop) = entry.key;
    final p = layout.positions[id]!;
    entry.value.sort((a, b) {
      final ap = layout.positions[a.other]!, bp = layout.positions[b.other]!;
      // Same-row arcs fan out toward their neighbour; incoming upper-row
      // connectors occupy the middle. Sorting just by x puts incoming lines
      // outside a left arc and makes the two cross near the target port.
      int sector(GraphPosition other) => !isTop || other.top != p.top
          ? 1
          : logicalX(other) < logicalX(p)
          ? 0
          : 2;
      final bySector = sector(ap).compareTo(sector(bp));
      if (bySector != 0) return bySector;
      final byX = logicalX(ap).compareTo(logicalX(bp));
      if (byX != 0) return byX;
      final byY = ap.top.compareTo(bp.top);
      return byY != 0 ? byY : a.other.compareTo(b.other);
    });
    for (final (rank, item) in entry.value.indexed) {
      // Inset from rounded corners, spread evenly across the usable border.
      final count = entry.value.length;
      final slots = math.min(12, count);
      final slot = count <= 12 ? rank : (rank * (slots - 1) / (count - 1)).round();
      final x = logicalX(p) + 18 + (p.width - 36) * (slot + 1) / (slots + 1);
      assigned[(item.edge, id)] = (x: layout.rtl ? layout.width - x : x, y: p.top + (isTop ? 0 : p.height));
    }
  }
  return [
    for (final (i, e) in endpoints.indexed)
      (a: e.a, b: e.b, sameRow: e.sameRow, start: assigned[(i, e.a)]!, end: assigned[(i, e.b)]!),
  ];
}

double _arcRise(GraphPoint a, GraphPoint b) {
  final span = (b.x - a.x).abs() / (GraphLayout.nodeWidth + GraphLayout.gapX);
  return 18 + 24 * span / (1 + span);
}

List<GraphEdge> buildGraphEdges(GraphLayout layout) => _edgesFromPorts(layout, _assignGraphPorts(layout));

List<GraphEdge> _edgesFromPorts(GraphLayout layout, List<_GraphPort> ports) => [
  for (final (i, p) in ports.indexed)
    (() {
      final ap = layout.positions[p.a]!, bp = layout.positions[p.b]!;
      final a = (x: p.start.x, y: ap.top + (p.sameRow ? 0 : ap.height));
      final b = (x: p.end.x, y: bp.top);
      final bend = p.sameRow ? _arcRise(a, b) * 4 / 3 : (b.y - a.y) / 2;
      return GraphEdge(
        layout.links[i],
        a,
        (x: a.x, y: p.sameRow ? a.y - bend : a.y + bend),
        (x: b.x, y: b.y - bend),
        b,
      );
    })(),
];

/// Canvas-space tap, screen-space tolerance. Cards always win. Only called on
/// completed taps, not pointer moves; O(cards + edges + candidate segments).
GraphEdge? hitTestGraphEdge(GraphLayout layout, GraphPoint point, {double scale = 1, double tolerance = 24}) {
  assert(scale > 0);
  for (final p in layout.positions.values) {
    if (point.x >= p.left && point.x <= p.left + p.width && point.y >= p.top && point.y <= p.top + p.height) {
      return null;
    }
  }
  for (final h in layout.obstacles) {
    if (point.x >= h.left && point.x <= h.left + h.width && point.y >= h.top && point.y <= h.top + h.height) {
      return null;
    }
  }
  // Overflow cards are interactive too.
  for (final row in [...layout.rows.where((r) => r.hiddenCount > 0)]) {
    final p = layout.positionInRow(row.index, row.visible.length);
    if (point.x >= p.left && point.x <= p.left + p.width && point.y >= p.top && point.y <= p.top + p.height) {
      return null;
    }
  }
  if (layout.hiddenRows.isNotEmpty) {
    final p = layout.morePosition;
    if (point.x >= p.left && point.x <= p.left + p.width && point.y >= p.top && point.y <= p.top + p.height) {
      return null;
    }
  }
  final reach = tolerance / scale;
  var best = reach * reach;
  GraphEdge? nearest;
  for (final edge in layout.edges) {
    if (point.x < edge.left - reach ||
        point.x > edge.right + reach ||
        point.y < edge.top - reach ||
        point.y > edge.bottom + reach) {
      continue;
    }
    for (var i = 1; i < edge.points.length; i++) {
      final distance = _distanceSquared(point, edge.points[i - 1], edge.points[i]);
      if (distance < best) {
        best = distance;
        nearest = edge;
      }
    }
  }
  return nearest;
}
