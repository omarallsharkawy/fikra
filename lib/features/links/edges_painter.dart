part of 'links_screen.dart';

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({required this.paths, required this.selected, required this.accent, required this.suggestionColor})
    : dimmed = _dimmedEdges(paths, selected);

  static Set<String> _dimmedEdges(GraphEdgePaths paths, String? selected) {
    if (selected == null) return const {};
    return {
      for (final e in paths.layout.links)
        if (e.sourceId != selected && e.targetId != selected) e.id,
    };
  }

  final GraphEdgePaths paths;
  final String? selected;
  final Color accent, suggestionColor;
  final Set<String> dimmed;

  @visibleForTesting
  int paintCount = 0;

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      paintCount++;
      return true;
    }());
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint();
    for (final cached in paths.edges) {
      final edge = cached.geometry;
      final link = edge.link;
      final dim = dimmed.contains(link.id);
      final opacity = dim ? 0.16 : 1.0;
      final color = link.isUser ? accent.withValues(alpha: opacity) : suggestionColor.withValues(alpha: opacity * 0.55);
      stroke
        ..strokeWidth = link.isUser ? 2 : 1.2
        ..color = color;
      if (link.isUser) {
        canvas.drawPath(cached.path, stroke);
      } else {
        canvas.drawRawPoints(PointMode.lines, cached.dashPoints, stroke);
      }
      dot.color = color;
      canvas.drawCircle(Offset(edge.start.x, edge.start.y), 3, dot);
      canvas.drawCircle(Offset(edge.end.x, edge.end.y), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      !paths.sameInk(old.paths) ||
      !setEquals(old.dimmed, dimmed) ||
      old.accent != accent ||
      old.suggestionColor != suggestionColor;
}

/// Real Text widgets supply direction, system text scaling and ellipsis. Only
/// selected incident labels are built; capsules are painted above cards/edges
/// and ignore pointers so their line remains tappable.
class _ReasonCapsule extends StatelessWidget {
  const _ReasonCapsule({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.colors.glass,
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: Border.all(color: context.colors.borderGraph),
        ),
        child: Text(
          label,
          style: context.text.meta.copyWith(color: context.colors.textLink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}
