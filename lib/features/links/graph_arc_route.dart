part of 'graph_layout.dart';

/// Keep the ranked border ports. A short exit below the label/control line
/// reaches a free arc span instead of merging or moving crowded port slots.
GraphEdge? _skirtArc(GraphLayout layout, GraphEdge e, List<GraphPosition> boxes) {
  double logical(double x) => layout.rtl ? layout.width - x : x;
  double physical(double x) => layout.rtl ? layout.width - x : x;
  final a = e.start, b = e.end, ax = logical(a.x), bx = logical(b.x);
  var right = ax, left = bx;
  for (final r in boxes) {
    if (r.top >= a.y || r.top + r.height <= a.y - 64) continue;
    final lo = layout.rtl ? layout.width - r.left - r.width : r.left, hi = lo + r.width;
    if (hi <= ax || lo >= bx) continue;
    right = math.max(right, hi + 4);
    left = math.min(left, lo - 4);
  }
  final ranges = [(right, bx), (ax, left)];
  for (final (lo, hi) in ranges) {
    if (hi - lo < 8) continue;
    final start = (x: physical(lo), y: a.y - 4), end = (x: physical(hi), y: b.y - 4);
    final bend = math.max(0, _arcRise(a, b) - 4) * 4 / 3;
    final curves = <GraphCubic>[
      (start: a, control1: (x: a.x, y: a.y - 2), control2: (x: start.x, y: a.y - 2), end: start),
      (start: start, control1: (x: start.x, y: start.y - bend), control2: (x: end.x, y: end.y - bend), end: end),
      (start: end, control1: (x: end.x, y: b.y - 2), control2: (x: b.x, y: b.y - 2), end: b),
    ];
    final routed = GraphEdge(e.link, a, curves.first.control1, curves.last.control2, b, segments: curves);
    if (!_edgeHits(routed, boxes)) return routed;
  }
  return null;
}
