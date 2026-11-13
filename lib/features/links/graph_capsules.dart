import 'dart:ui';

import 'graph_layout.dart';

typedef GraphCapsule = ({GraphEdge edge, Rect rect});

/// Selection-only placement. Try the midpoint, slide in both directions,
/// narrow once needed, then omit labels that cannot fit without collisions.
List<GraphCapsule> layoutGraphCapsules(
  GraphLayout layout,
  String? selected, {
  required List<Rect> obstacles,
  required Size Function(String label, double maxWidth) measure,
}) {
  if (selected == null) return const [];
  final result = <GraphCapsule>[];
  final blocked = obstacles.map((r) => r.inflate(4)).toList();
  final edges =
      layout.edges
          .where((e) => (e.link.sourceId == selected || e.link.targetId == selected) && e.link.label.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.link.id.compareTo(b.link.id));
  final canvas = Rect.fromLTWH(0, 0, layout.width, layout.height);
  for (final edge in edges) {
    Rect? placed;
    for (final width in [160.0, 128.0, 96.0, 72.0]) {
      final size = measure(edge.link.label, width);
      for (final t in [0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8]) {
        final p = edge.pointAt(t);
        final rect = Rect.fromCenter(center: Offset(p.x, p.y), width: size.width, height: size.height);
        if (!canvas.contains(rect.topLeft) || !canvas.contains(rect.bottomRight) || blocked.any(rect.overlaps)) {
          continue;
        }
        placed = rect;
        break;
      }
      if (placed != null) break;
    }
    if (placed == null) continue;
    result.add((edge: edge, rect: placed));
    blocked.add(placed.inflate(4));
  }
  return result;
}
