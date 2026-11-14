part of 'graph_layout.dart';

/// Shared spatial buckets keep card avoidance proportional to the route's ink,
/// rather than multiplying every candidate curve by all 240 cards.
class _RouteIndex {
  _RouteIndex(GraphLayout layout, this.reserved) : framed = layout.frames.isNotEmpty {
    entries = [
      for (final box in reserved) (id: null, box: box),
      for (final e in layout.positions.entries) (id: e.key, box: e.value),
      for (final row in layout.rows)
        if (row.hiddenCount > 0) (id: null, box: layout.positionInRow(row.index, row.visible.length)),
      if (layout.hiddenRows.isNotEmpty) (id: null, box: layout.morePosition),
    ];
    final ordered = entries.skip(reserved.length).toList()..sort((a, b) => a.box.top.compareTo(b.box.top));
    for (final entry in ordered) {
      final r = entry.box;
      if (bands.isNotEmpty && r.top <= bands.last.$2) {
        bands[bands.length - 1] = (bands.last.$1, math.max(bands.last.$2, r.top + r.height));
      } else {
        bands.add((r.top, r.top + r.height));
      }
    }
    for (final entry in entries.skip(reserved.length)) {
      final r = entry.box;
      minX = math.min(minX, r.left);
      maxX = math.max(maxX, r.left + r.width);
      minY = math.min(minY, r.top);
      maxY = math.max(maxY, r.top + r.height);
      for (var x = (r.left / _cell).floor(); x <= ((r.left + r.width) / _cell).floor(); x++) {
        for (var y = (r.top / _cell).floor(); y <= ((r.top + r.height) / _cell).floor(); y++) {
          (cells[(x, y)] ??= []).add(entry);
        }
      }
    }
  }
  final bool framed;
  static const _cell = 132.0;
  double minX = double.infinity, minY = double.infinity;
  double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  final bands = <(double, double)>[];
  bool overlaps(double left, double top, double right, double bottom) {
    if (right <= minX || left >= maxX || bottom <= minY || top >= maxY) return false;
    var lo = 0, hi = bands.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (bands[mid].$2 <= top) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo < bands.length && bands[lo].$1 < bottom;
  }

  final List<GraphPosition> reserved;
  late final List<({String? id, GraphPosition box})> entries;
  final cells = <(int, int), List<({String? id, GraphPosition box})>>{};
}

class _RouteBoxes extends Iterable<GraphPosition> {
  _RouteBoxes(this.index, GraphLink link) : source = link.sourceId, target = link.targetId;
  final _RouteIndex index;
  final String source, target;

  @override
  Iterator<GraphPosition> get iterator =>
      index.entries.where((e) => e.id != source && e.id != target).map((e) => e.box).iterator;

  bool sampleHitsCards(GraphEdge edge) {
    // A point strictly inside a card proves a collision. Early positives avoid
    // flattening a long direct cubic which will be discarded for a gutter.
    for (final t in const [0.5, 0.25, 0.75, 0.125, 0.875]) {
      final p = edge.pointAt(t);
      final candidates = index.cells[((p.x / _RouteIndex._cell).floor(), (p.y / _RouteIndex._cell).floor())];
      if (candidates == null) continue;
      for (final entry in candidates) {
        if (entry.id == source || entry.id == target) continue;
        final r = entry.box;
        if (p.x > r.left && p.x < r.left + r.width && p.y > r.top && p.y < r.top + r.height) return true;
      }
    }
    return false;
  }

  bool hitsCards(GraphEdge edge) {
    // Most gutter pieces lie wholly between card rows. Test their small
    // control hulls first; a route's overall bounds span unrelated rows.
    for (final c in edge.curves) {
      final left = math.min(math.min(c.start.x, c.end.x), math.min(c.control1.x, c.control2.x));
      final right = math.max(math.max(c.start.x, c.end.x), math.max(c.control1.x, c.control2.x));
      final top = math.min(math.min(c.start.y, c.end.y), math.min(c.control1.y, c.control2.y));
      final bottom = math.max(math.max(c.start.y, c.end.y), math.max(c.control1.y, c.control2.y));
      if (!index.overlaps(left, top, right, bottom)) continue;
      for (var x = (left / _RouteIndex._cell).floor(); x <= (right / _RouteIndex._cell).floor(); x++) {
        for (var y = (top / _RouteIndex._cell).floor(); y <= (bottom / _RouteIndex._cell).floor(); y++) {
          final candidates = index.cells[(x, y)];
          if (candidates == null) continue;
          for (final entry in candidates) {
            if (entry.id == source || entry.id == target) continue;
            final r = entry.box;
            if (right <= r.left || left >= r.left + r.width || bottom <= r.top || top >= r.top + r.height) continue;
            final points = edge.points;
            for (var i = 1; i < points.length; i++) {
              if (graphSegmentIntersectsRect(points[i - 1], points[i], r)) return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool intersects(GraphPoint a, GraphPoint b) =>
      index.reserved.any((r) => graphSegmentIntersectsRect(a, b, r)) || intersectsCards(a, b);

  bool intersectsCards(GraphPoint a, GraphPoint b) {
    final left = math.min(a.x, b.x), right = math.max(a.x, b.x);
    final top = math.min(a.y, b.y), bottom = math.max(a.y, b.y);
    if (!index.overlaps(left, top, right, bottom)) return false;
    for (var x = (left / _RouteIndex._cell).floor(); x <= (right / _RouteIndex._cell).floor(); x++) {
      for (var y = (top / _RouteIndex._cell).floor(); y <= (bottom / _RouteIndex._cell).floor(); y++) {
        final candidates = index.cells[(x, y)];
        if (candidates == null) continue;
        for (final entry in candidates) {
          if (entry.id == source || entry.id == target) continue;
          if (graphSegmentIntersectsRect(a, b, entry.box)) return true;
        }
      }
    }
    return false;
  }
}
