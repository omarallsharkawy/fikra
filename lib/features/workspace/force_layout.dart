import 'dart:math' as math;
import 'dart:ui';

/// Geometry only: the caller supplies every node and edge from its repository.
/// Inputs/results can cross an isolate boundary for larger graphs.
class ForceLayoutInput {
  const ForceLayoutInput(this.ids, this.edges, {this.previous = const {}, this.fixed = const {}});
  final List<String> ids;
  final List<(String, String)> edges;
  final Map<String, Offset> previous;
  final Set<String> fixed;
  double get side => math.max(360, math.sqrt(ids.length) * 85);
}

Map<String, Offset> forceGraphLayout(ForceLayoutInput input) {
  final ids = input.ids.toSet().toList()..sort();
  if (ids.isEmpty) return {};
  final side = input.side, center = Offset(side / 2, side / 2);
  final positions = <String, Offset>{};
  final velocity = <String, Offset>{};
  for (final (i, id) in ids.indexed) {
    // Stable ID jitter breaks exact symmetries without random render changes.
    var hash = 17;
    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final angle = i * 2.399963229728653 + (hash % 97) / 200;
    final radius = ids.length == 1 ? 0.0 : math.sqrt((i + .5) / ids.length) * side * .37;
    final previous = input.previous[id];
    positions[id] = previous != null && previous.dx.isFinite && previous.dy.isFinite
        ? previous
        : center + Offset(math.cos(angle), math.sin(angle)) * radius;
    velocity[id] = Offset.zero;
  }
  final edges = input.edges
      .where((e) => positions.containsKey(e.$1) && positions.containsKey(e.$2) && e.$1 != e.$2)
      .toSet();
  final steps = ids.length > 500 ? 100 : 220;
  for (var step = 0; step < steps; step++) {
    final force = {for (final id in ids) id: (center - positions[id]!) * .003};
    // A spatial grid bounds repulsion work on large graphs. Beyond the local
    // 240px horizon, centering and springs handle disconnected components.
    final cells = <(int, int), List<String>>{};
    if (ids.length > 120) {
      for (final id in ids) {
        final p = positions[id]!;
        cells.putIfAbsent(((p.dx / 120).floor(), (p.dy / 120).floor()), () => []).add(id);
      }
    }
    for (var i = 0; i < ids.length; i++) {
      final a = ids[i], p = positions[ids[i]]!;
      Iterable<String> neighbors = ids.skip(i + 1);
      if (cells.isNotEmpty) {
        final cell = ((p.dx / 120).floor(), (p.dy / 120).floor());
        neighbors = [
          for (var x = -2; x <= 2; x++)
            for (var y = -2; y <= 2; y++) ...?cells[(cell.$1 + x, cell.$2 + y)],
        ].where((b) => a.compareTo(b) < 0);
      }
      for (final b in neighbors) {
        var delta = p - positions[b]!;
        if (delta.distanceSquared < .01) delta = const Offset(.1, .05);
        final distance = math.max(1.0, delta.distance);
        final strength = 220 / distance + (distance < 58 ? (58 - distance) * .2 : 0);
        final push = delta / distance * strength;
        force[a] = force[a]! + push;
        force[b] = force[b]! - push;
      }
    }
    for (final edge in edges) {
      final delta = positions[edge.$2]! - positions[edge.$1]!;
      final distance = math.max(1.0, delta.distance);
      final spring = delta / distance * (distance - 60) * .06;
      force[edge.$1] = force[edge.$1]! + spring;
      force[edge.$2] = force[edge.$2]! - spring;
    }
    final cap = 6 * (1 - step / steps) + .12;
    for (final id in ids) {
      if (input.fixed.contains(id)) continue;
      var v = (velocity[id]! + force[id]!) * .72;
      if (v.distance > cap) v = v / v.distance * cap;
      final next = positions[id]! + v;
      positions[id] = Offset(next.dx.clamp(40, side - 40), next.dy.clamp(40, side - 58));
      velocity[id] = v;
    }
  }
  return positions;
}
