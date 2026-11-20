import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One static flat canvas behind content; unrelated scroll/press paints cannot dirty it.
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
  void paintRect(Canvas canvas, Rect rect, {double opacity = 1}) {
    canvas.drawRect(rect, Paint()..color = colors.canvas.withValues(alpha: opacity));
  }

  @override
  void paint(Canvas canvas, Size size) => paintRect(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(PearlCanvasPainter old) => old.colors != colors;
}
