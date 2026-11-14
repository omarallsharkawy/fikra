part of 'graph_layout.dart';

String _endpointId(GraphLayout l, GraphPoint p, GraphLink link) {
  final s = l.positions[link.sourceId]!;
  return (p.y == s.top || p.y == s.top + s.height) && p.x >= s.left && p.x <= s.left + s.width
      ? link.sourceId
      : link.targetId;
}

/// Project the existing ranked slots onto free border sectors. Shared slots
/// stay shared; if projection would merge distinct slots, distribute those
/// slots across the remaining border instead (still at most twelve).
Map<(String, double), double> _safeTopPorts(GraphLayout l, List<GraphEdge> edges, List<GraphPosition> boxes) {
  final slots = <String, Set<double>>{}, towards = <(String, double), GraphPoint>{};
  void add(GraphPoint p, GraphLink link, GraphPoint? other) {
    final id = _endpointId(l, p, link);
    (slots[id] ??= {}).add(p.x);
    if (other != null) towards[(id, p.x)] = other;
  }

  for (final e in edges) {
    final same = e.start.y == e.end.y;
    if (same) add(e.start, e.link, e.end);
    add(e.end, e.link, same ? e.start : null);
  }
  final result = <(String, double), double>{};
  for (final entry in slots.entries) {
    final id = entry.key, c = l.positions[id]!, y = c.top;
    final xs = entry.value.toList()..sort();
    bool free(double x) => !boxes.any((r) => graphSegmentIntersectsRect((x: x, y: y), (x: x, y: y - 4), r));
    if (xs.every(free)) continue;
    final candidates = [
      c.left + 18,
      c.left + c.width - 18,
      for (final r in boxes) ...[r.left - 1, r.left + r.width + 1],
    ].where((x) => x >= c.left + 18 && x <= c.left + c.width - 18 && free(x)).toSet();
    final mapped = <double>[];
    for (final x in xs) {
      if (free(x)) {
        mapped.add(x);
        continue;
      }
      final toward = towards[(id, x)];
      final choices = candidates.toList()
        ..sort((a, b) {
          if (toward != null) {
            final ap = (a - x) * (toward.x - x) > 0, bp = (b - x) * (toward.x - x) > 0;
            if (ap != bp) return ap ? -1 : 1;
          }
          final d = (a - x).abs().compareTo((b - x).abs());
          return d == 0 ? (l.rtl ? b.compareTo(a) : a.compareTo(b)) : d;
        });
      mapped.add(choices.isEmpty ? x : choices.first);
    }
    if (mapped.toSet().length < xs.length) {
      var ranges = [(c.left + 18, c.left + c.width - 18)];
      for (final r in boxes) {
        if (r.top >= y || r.top + r.height <= y - 4) continue;
        final next = <(double, double)>[];
        for (final (a, b) in ranges) {
          if (r.left >= b || r.left + r.width <= a) {
            next.add((a, b));
            continue;
          }
          if (a < r.left - 1) next.add((a, math.min(b, r.left - 1)));
          if (b > r.left + r.width + 1) next.add((math.max(a, r.left + r.width + 1), b));
        }
        ranges = next;
      }
      final total = ranges.fold(0.0, (s, r) => s + r.$2 - r.$1);
      if (total > 0) {
        for (var i = 0; i < xs.length; i++) {
          var distance = total * (i + 1) / (xs.length + 1);
          for (final (a, b) in ranges) {
            if (distance <= b - a) {
              mapped[i] = a + distance;
              break;
            }
            distance -= b - a;
          }
        }
      }
    }
    for (final (i, x) in xs.indexed) {
      result[(id, x)] = mapped[i];
    }
  }
  return result;
}
