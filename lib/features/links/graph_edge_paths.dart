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
  List<Vertices> dashVertices(int capDivisions) => ink.dashVertices(capDivisions);

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

  final _dashVertices = <int, List<Vertices>>{};

  /// Built on first Impeller paint at each cap resolution a zoom level needs
  /// (at most a few), then kept with the ink across layouts.
  List<Vertices> dashVertices(int capDivisions) =>
      _dashVertices[capDivisions] ??= graphDashCapsules(dashPoints, divisions: capDivisions);
}

/// Stroke width of a suggestion's dashes, shared by the painter and the capsules.
const graphSuggestionStroke = 1.2;

/// Impeller has no raster cache, so the canvas picture is replayed on every pan
/// frame, and it expands `drawRawPoints(PointMode.lines)` into one draw with its
/// own round-cap tessellation per dash. These triangle strips are tessellated
/// once and replayed as one draw per [extent]-sized run of dashes, which the
/// picture's spatial index can skip off screen. Each capsule is the polygon
/// Impeller tessellates for a round-capped line at the current device scale
/// ([divisions] steps per quarter turn, see [graphCapDivisions]). Strips
/// are joined by zero-area triangles, so nothing is drawn twice that separate
/// lines would not also draw twice.
List<Vertices> graphDashCapsules(Float32List dashes, {required int divisions, double extent = 256}) {
  final n = divisions;
  const r = graphSuggestionStroke / 2;
  final cos = [for (var k = 0; k <= n; k++) math.cos(k * math.pi / (2 * n)) * r];
  final sin = [for (var k = 0; k <= n; k++) math.sin(k * math.pi / (2 * n)) * r];
  final buffer = Float32List(dashes.length ~/ 4 * (4 * n + 4) * 2);
  final out = <Vertices>[];
  var written = 0, start = 0;
  var left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
  void put(double x, double y) {
    buffer[written++] = x;
    buffer[written++] = y;
  }

  void flush() {
    if (written > start) {
      out.add(Vertices.raw(VertexMode.triangleStrip, Float32List.sublistView(buffer, start, written)));
    }
    start = written;
  }

  for (var i = 0; i + 3 < dashes.length; i += 4) {
    final x0 = dashes[i], y0 = dashes[i + 1], x1 = dashes[i + 2], y1 = dashes[i + 3];
    final l = math.min(x0, x1), t = math.min(y0, y1), rt = math.max(x0, x1), b = math.max(y0, y1);
    if (written > start &&
        (math.max(right, rt) - math.min(left, l) > extent || math.max(bottom, b) - math.min(top, t) > extent)) {
      flush();
    }
    if (written == start) {
      (left, top, right, bottom) = (l, t, rt, b);
    } else {
      (left, top, right, bottom) = (math.min(left, l), math.min(top, t), math.max(right, rt), math.max(bottom, b));
    }
    final length = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    // A zero-length dash is a dot, as a round-capped line of length 0 is.
    final ux = length == 0 ? 1.0 : (x1 - x0) / length, uy = length == 0 ? 0.0 : (y1 - y0) / length;
    final vx = -uy, vy = ux;
    if (written > start) {
      put(buffer[written - 2], buffer[written - 1]);
      put(x0 - r * ux, y0 - r * uy);
    }
    put(x0 - r * ux, y0 - r * uy);
    for (var k = 1; k <= n; k++) {
      put(x0 - cos[k] * ux + sin[k] * vx, y0 - cos[k] * uy + sin[k] * vy);
      put(x0 - cos[k] * ux - sin[k] * vx, y0 - cos[k] * uy - sin[k] * vy);
    }
    for (var k = n; k >= 1; k--) {
      put(x1 + cos[k] * ux + sin[k] * vx, y1 + cos[k] * uy + sin[k] * vy);
      put(x1 + cos[k] * ux - sin[k] * vx, y1 + cos[k] * uy - sin[k] * vy);
    }
    put(x1 + r * ux, y1 + r * uy);
  }
  flush();
  return out;
}

/// Impeller's quarter-circle steps for a round cap of [pixelRadius] device
/// pixels (`kPrecomputedDivisions` in impeller/tessellator/tessellator.cc), so
/// the capsules match the lines Impeller would draw at the same zoom.
int graphCapDivisions(double pixelRadius) {
  const steps = [1, 2, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 7];
  if (pixelRadius <= 0) return 1;
  return steps[math.min(pixelRadius.ceil(), steps.length - 1)];
}
