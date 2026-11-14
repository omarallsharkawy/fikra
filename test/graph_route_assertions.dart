import 'package:fikra/features/links/graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Endpoint cards own their ports. Every other card, capsule, overflow, label
/// and control must be clear, independently of the production routing index.
Iterable<GraphPosition> graphRouteObstacles(GraphLayout layout, GraphEdge edge) sync* {
  yield* layout.obstacles;
  for (final p in layout.positions.entries) {
    if (p.key != edge.link.sourceId && p.key != edge.link.targetId) yield p.value;
  }
  for (final row in layout.rows) {
    if (row.hiddenCount > 0) yield layout.positionInRow(row.index, row.visible.length);
  }
  if (layout.hiddenRows.isNotEmpty) yield layout.morePosition;
}

void expectClearGraphInk(GraphLayout layout) {
  for (final e in layout.edges) {
    for (final r in graphRouteObstacles(layout, e)) {
      for (var i = 1; i < e.points.length; i++) {
        expect(
          graphSegmentIntersectsRect(e.points[i - 1], e.points[i], r),
          isFalse,
          reason: '${e.link.id} crosses $r at ${e.points[i - 1]} → ${e.points[i]}',
        );
      }
    }
  }
}
