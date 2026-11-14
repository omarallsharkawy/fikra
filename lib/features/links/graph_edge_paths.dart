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
      a.end == b.end &&
      a.curves.length == b.curves.length &&
      List.generate(a.curves.length, (i) => a.curves[i] == b.curves[i]).every((v) => v);
}

/// One cubic path and one packed line-segment buffer. Dash subdivision walks
/// the already flattened curve once; no metrics or per-dash engine Paths.
class GraphEdgeInk {
  GraphEdgeInk(GraphEdge e) {
    path = Path()..moveTo(e.start.x, e.start.y);
    for (final c in e.curves) {
      if (c.start.x == c.control1.x && c.start.x == c.control2.x && c.start.x == c.end.x) {
        path.lineTo(c.end.x, c.end.y);
      } else {
        path.cubicTo(c.control1.x, c.control1.y, c.control2.x, c.control2.y, c.end.x, c.end.y);
      }
    }
    if (e.link.isUser) {
      dashPoints = Float32List(0);
      return;
    }
    final lengths = <double>[];
    var total = 0.0;
    for (var i = 1; i < e.points.length; i++) {
      final a = e.points[i - 1], b = e.points[i];
      final len = math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
      lengths.add(len);
      total += len;
    }
    // One packed allocation. No temporary List or division per dash, including
    // long gutter runs. A view trims the conservative per-segment capacity.
    final buffer = Float32List((total / 10 + 2 * e.points.length + 1).ceil() * 4);
    var written = 0, travelled = 0.0;
    for (final (i, length) in lengths.indexed) {
      if (length < 1e-9) continue;
      final a = e.points[i], b = e.points[i + 1];
      final ux = (b.x - a.x) / length, uy = (b.y - a.y) / length;
      final phase = travelled % 10;
      var position = phase < 5 ? 0.0 : 10 - phase;
      var dash = phase < 5 ? 5 - phase : 5.0;
      while (position < length) {
        final end = math.min(length, position + dash);
        buffer[written++] = a.x + ux * position;
        buffer[written++] = a.y + uy * position;
        buffer[written++] = a.x + ux * end;
        buffer[written++] = a.y + uy * end;
        position += dash + 5;
        dash = 5;
      }
      travelled += length;
    }
    dashPoints = Float32List.sublistView(buffer, 0, written);
  }

  late final Path path;
  late final Float32List dashPoints;
}
