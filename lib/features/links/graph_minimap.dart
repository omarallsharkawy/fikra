import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/localizations.dart';
import 'graph_layout.dart';

/// The visible scene rectangle, independent of reading direction.
Rect graphViewportRect(Matrix4 transform, Size viewport) =>
    MatrixUtils.transformRect(Matrix4.inverted(transform), Offset.zero & viewport);

/// Logical end placement belongs to the host. Content and viewport have separate
/// repaint boundaries: gestures never record or repaint the content layer.
class GraphMinimap extends StatefulWidget {
  const GraphMinimap({
    super.key,
    required this.layout,
    required this.controller,
    required this.viewportSize,
    required this.onMove,
    this.obscured = false,
  });
  final GraphLayout layout;
  final TransformationController controller;
  final Size viewportSize;
  final ValueChanged<Offset> onMove;
  final bool obscured;
  static const mapSize = Size(112, 84);

  @override
  State<GraphMinimap> createState() => _GraphMinimapState();
}

class _GraphMinimapState extends State<GraphMinimap> {
  _MinimapContent? _content;

  @override
  void dispose() {
    _content?.picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final colors = context.colors;
    if (_content == null || !identical(_content!.layout, layout) || _content!.color != colors.borderGraph) {
      _content?.picture.dispose();
      _content = _MinimapContent(layout, colors.borderGraph);
    }
    final content = _content!;
    void move(Offset local) => widget.onMove(content.toScene(local));
    final ink = RepaintBoundary(
      child: CustomPaint(key: const ValueKey('graph-minimap-content'), size: GraphMinimap.mapSize, painter: content),
    );
    return AnimatedBuilder(
      animation: widget.controller,
      child: ink,
      builder: (context, child) {
        final viewport = widget.viewportSize;
        // Unknown size, or the whole graph already in view: nothing to map.
        if (widget.obscured || viewport.isEmpty) return const SizedBox.shrink();
        final visible = graphViewportRect(widget.controller.value, viewport);
        if (layout.width <= visible.width + 0.5 && layout.height <= visible.height + 0.5) {
          return const SizedBox.shrink();
        }
        return Semantics(
          label: context.l10n.graphMinimap,
          button: true,
          onTap: () => widget.onMove(Offset(layout.width / 2, layout.height / 2)),
          child: Container(
            key: const ValueKey('graph-minimap'),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: colors.screen,
              border: Border.all(color: colors.borderGraph),
              borderRadius: BorderRadius.circular(FikraRadius.sm),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown: (d) => move(d.localPosition),
              onPanStart: (d) => move(d.localPosition),
              onPanUpdate: (d) => move(d.localPosition),
              child: SizedBox.fromSize(
                size: GraphMinimap.mapSize,
                child: Stack(
                  children: [
                    Positioned.fill(child: child!),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          key: const ValueKey('graph-minimap-viewport'),
                          painter: GraphMinimapViewport(content.toMap(visible), colors.accentLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MinimapContent extends CustomPainter {
  _MinimapContent(this.layout, this.color) {
    scale = math.min(
      (GraphMinimap.mapSize.width - 8) / layout.width,
      (GraphMinimap.mapSize.height - 8) / layout.height,
    );
    origin = Offset(
      (GraphMinimap.mapSize.width - layout.width * scale) / 2,
      (GraphMinimap.mapSize.height - layout.height * scale) / 2,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final frame = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final card = Paint()..color = color;
    for (final f in layout.frames) {
      canvas.drawRect(toMap(_rect(f.bounds)), frame);
    }
    for (final p in layout.positions.values) {
      canvas.drawRect(toMap(_rect(p)), card);
    }
    for (final r in layout.rows.where((r) => r.hiddenCount > 0)) {
      canvas.drawRect(toMap(_rect(layout.positionInRow(r.index, r.visible.length))), card);
    }
    if (layout.hiddenRows.isNotEmpty) canvas.drawRect(toMap(_rect(layout.morePosition)), card);
    picture = recorder.endRecording();
  }
  final GraphLayout layout;
  final Color color;
  late final double scale;
  late final Offset origin;
  late final ui.Picture picture;
  @visibleForTesting
  int paintCount = 0;
  Rect toMap(Rect r) =>
      Rect.fromLTWH(origin.dx + r.left * scale, origin.dy + r.top * scale, r.width * scale, r.height * scale);
  Offset toScene(Offset p) =>
      Offset(((p.dx - origin.dx) / scale).clamp(0, layout.width), ((p.dy - origin.dy) / scale).clamp(0, layout.height));
  static Rect _rect(GraphPosition p) => Rect.fromLTWH(p.left, p.top, p.width, p.height);
  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      paintCount++;
      return true;
    }());
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _MinimapContent old) => !identical(this, old);
}

class GraphMinimapViewport extends CustomPainter {
  GraphMinimapViewport(this.rect, this.color);
  final Rect rect;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    rect.intersect(Offset.zero & size).deflate(0.5),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
  @override
  bool shouldRepaint(GraphMinimapViewport old) => old.rect != rect || old.color != color;
}
