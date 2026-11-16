import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One static canvas behind content; unrelated scroll/press paints cannot dirty it.
class PearlCanvas extends StatelessWidget {
  const PearlCanvas({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: RepaintBoundary(child: CustomPaint(painter: PearlCanvasPainter(context.colors))),
      ),
      child,
    ],
  );
}

class PearlCanvasPainter extends CustomPainter {
  const PearlCanvasPainter(this.colors);
  final FikraPalette colors;

  /// Shared with the existing tab veil, including its background anchor.
  /// CSS ellipse/farthest-corner geometry; cool is composited over warm.
  void paintRect(Canvas canvas, Rect rect, {double opacity = 1}) {
    assert(colors.washAlpha == 0, 'Pearl has exactly two blooms and no wash');
    canvas.drawRect(rect, Paint()..color = colors.canvas.withValues(alpha: opacity));
    void bloom(Color color, double alpha, double x, double y, double stop) {
      final centre = Offset(rect.width * x, rect.height * y);
      final rx = math.max(centre.dx, rect.width - centre.dx) * math.sqrt2;
      final ry = math.max(centre.dy, rect.height - centre.dy) * math.sqrt2;
      if (rx == 0 || ry == 0) return;
      canvas.save();
      canvas.translate(rect.left + centre.dx, rect.top + centre.dy);
      canvas.scale(rx, ry);
      canvas.drawRect(
        Rect.fromLTRB(-centre.dx / rx, -centre.dy / ry, (rect.width - centre.dx) / rx, (rect.height - centre.dy) / ry),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            1,
            [color.withValues(alpha: alpha * opacity), color.withValues(alpha: 0)],
            [0, stop],
          ),
      );
      canvas.restore();
    }

    bloom(colors.bloomWarm, colors.bloomWarmAlpha, 0, .90, .52);
    bloom(colors.bloomCool, colors.bloomCoolAlpha, 1, .97, .50);
  }

  @override
  void paint(Canvas canvas, Size size) => paintRect(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(PearlCanvasPainter old) => old.colors != colors;
}
