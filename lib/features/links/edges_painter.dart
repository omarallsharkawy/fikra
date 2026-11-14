part of 'links_screen.dart';

/// Overrides the backend check in widget tests, which render with Skia.
@visibleForTesting
bool? debugGraphDashVertices;

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.paths,
    required this.selected,
    required this.accent,
    required this.suggestionColor,
    required this.capDivisions,
  }) : dimmed = _dimmedEdges(paths, selected),
       // Impeller replays this picture on every pan frame and draws each dash of
       // a point list separately; prebuilt capsules keep a pan frame cheap. Skia
       // batches the point list itself and would not antialias the vertices.
       dashVertices = debugGraphDashVertices ?? ImageFilter.isShaderFilterSupported;

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
  final bool dashVertices;

  /// [graphCapDivisions] for the current zoom; only the capsules use it.
  final int capDivisions;

  @visibleForTesting
  int paintCount = 0;

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      paintCount++;
      return true;
    }());
    canvas.save();
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final r in paths.layout.obstacles) {
      mask.addRect(_rect(r).inflate(1.5));
    }
    canvas.clipPath(mask, doAntiAlias: false);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint();
    final fill = Paint();
    for (final cached in paths.edges) {
      final edge = cached.geometry;
      final link = edge.link;
      final dim = dimmed.contains(link.id);
      final opacity = dim ? 0.16 : 1.0;
      final color = link.isUser ? accent.withValues(alpha: opacity) : suggestionColor.withValues(alpha: opacity * 0.55);
      stroke
        ..strokeWidth = link.isUser ? 2 : graphSuggestionStroke
        ..color = color;
      if (link.isUser) {
        canvas.drawPath(cached.path, stroke);
      } else {
        if (dashVertices) {
          fill.color = color;
          for (final run in cached.dashVertices(capDivisions)) {
            canvas.drawVertices(run, BlendMode.srcOver, fill);
          }
        } else {
          canvas.drawRawPoints(PointMode.lines, cached.dashPoints, stroke);
        }
      }
      dot.color = color;
      canvas.drawCircle(Offset(edge.start.x, edge.start.y), 3, dot);
      canvas.drawCircle(Offset(edge.end.x, edge.end.y), 3, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      !paths.sameInk(old.paths) ||
      !listEquals(paths.layout.obstacles, old.paths.layout.obstacles) ||
      !setEquals(old.dimmed, dimmed) ||
      old.dashVertices != dashVertices ||
      (dashVertices && old.capDivisions != capDivisions) ||
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

/// Rebuilds the edge painter only when zooming changes how finely Impeller
/// would round a dash cap (a few steps across the whole zoom range), never
/// while panning.
class _CapResolution extends StatefulWidget {
  const _CapResolution({required this.controller, required this.builder});
  final TransformationController controller;
  final Widget Function(int capDivisions) builder;

  @override
  State<_CapResolution> createState() => _CapResolutionState();
}

class _CapResolutionState extends State<_CapResolution> {
  int? _divisions;
  double _pixelRatio = 1;

  int _current() => graphCapDivisions(graphSuggestionStroke / 2 * _pixelRatio * _scaleOf(widget.controller.value));

  void _changed() {
    if (_current() != _divisions) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(_CapResolution old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    old.controller.removeListener(_changed);
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return widget.builder(_divisions = _current());
  }
}
