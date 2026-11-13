import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'graph_layout.dart';

/// Bounded to the current layout's edges. A new wrapper carries current link
/// metadata; unchanged drawing data survives rename, reason and stream edits.
class GraphEdgePaths {
  GraphEdgePaths(this.layout, {GraphEdgePaths? previous}) {
    final old = {for (final e in previous?.edges ?? <CachedGraphEdge>[]) e.geometry.link.id: e};
    edges = [for (final e in layout.edges) CachedGraphEdge(e, previous: old[e.link.id])];
    rebuiltEdges = edges.where((e) => !identical(e.ink, old[e.geometry.link.id]?.ink)).length;
  }
  final GraphLayout layout;
  late final List<CachedGraphEdge> edges;
  late final int rebuiltEdges;

  bool sameInk(GraphEdgePaths other) {
    if (edges.length != other.edges.length) return false;
    for (var i = 0; i < edges.length; i++) {
      if (!identical(edges[i].ink, other.edges[i].ink)) return false;
    }
    return true;
  }

  Set<String> focus(String? selected) => selected == null
      ? const {}
      : {
          selected,
          for (final e in layout.links)
            if (e.sourceId == selected) e.targetId else if (e.targetId == selected) e.sourceId,
        };
}

class CachedGraphEdge {
  CachedGraphEdge(this.geometry, {CachedGraphEdge? previous})
    : ink = previous != null && _sameShape(geometry, previous.geometry) ? previous.ink : GraphEdgeInk(geometry);
  final GraphEdge geometry;
  final GraphEdgeInk ink;
  Path get path => ink.path;
  Float32List get dashPoints => ink.dashPoints;

  static bool _sameShape(GraphEdge a, GraphEdge b) =>
      a.link.id == b.link.id &&
      a.link.isUser == b.link.isUser &&
      a.start == b.start &&
      a.control1 == b.control1 &&
      a.control2 == b.control2 &&
      a.end == b.end;
}

/// One cubic path and one packed line-segment buffer. Dash subdivision walks
/// the already flattened curve once; no metrics or per-dash engine Paths.
class GraphEdgeInk {
  GraphEdgeInk(GraphEdge e) {
    path = Path()
      ..moveTo(e.start.x, e.start.y)
      ..cubicTo(e.control1.x, e.control1.y, e.control2.x, e.control2.y, e.end.x, e.end.y);
    final segments = <double>[];
    if (!e.link.isUser) {
      var travelled = 0.0;
      for (var i = 1; i < e.points.length; i++) {
        final a = e.points[i - 1], b = e.points[i];
        final dx = b.x - a.x, dy = b.y - a.y, length = math.sqrt(dx * dx + dy * dy);
        var position = 0.0;
        while (position < length) {
          final phase = travelled % 10;
          final on = phase < 5;
          final step = math.min(length - position, (on ? 5 : 10) - phase);
          if (step < 1e-9) {
            travelled += 1e-8;
            continue;
          }
          if (on) {
            segments.addAll([
              a.x + dx * position / length,
              a.y + dy * position / length,
              a.x + dx * (position + step) / length,
              a.y + dy * (position + step) / length,
            ]);
          }
          position += step;
          travelled += step;
        }
      }
    }
    dashPoints = Float32List.fromList(segments);
  }
  late final Path path;
  late final Float32List dashPoints;
}
