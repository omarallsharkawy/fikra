import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Static paint only: no ShaderMask, saveLayer, or animation controller.
class GlassEdge extends CustomPainter {
  const GlassEdge(this.colors, this.radius, {this.lens = false});
  final FikraPalette colors;
  final double radius;
  final bool lens;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final inner = outer.deflate(1);
    final rim = lens ? colors.lensRim : colors.rim;
    final alpha = lens ? colors.lensRimAlpha : colors.rimAlpha;
    canvas.drawDRRect(outer, inner, Paint()..color = rim.withValues(alpha: alpha));
    final gain = lens ? FikraPalette.lensSpectrumGain : 1.0;
    final a = colors.spectrumAlpha * gain;
    // CSS 125deg, masked by the geometry of this one-pixel ring.
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      transform: const PearlGradientAngle(125),
      colors: [
        colors.spectrumCool.withValues(alpha: a),
        Colors.transparent,
        colors.spectrumWarm.withValues(alpha: a),
        Colors.transparent,
        colors.spectrumSage.withValues(alpha: a),
      ],
      stops: const [0, .23, .49, .73, 1],
    );
    canvas.drawDRRect(outer, inner, Paint()..shader = gradient.createShader(rect));
    canvas.save();
    canvas.clipRRect(inner);
    // Inset top light and contact shade stay outside the text-bearing area.
    canvas.drawLine(
      const Offset(1, 1.5),
      Offset(size.width - 1, 1.5),
      Paint()
        ..color = colors.highlight.withValues(alpha: lens ? colors.lensHighlightAlpha : colors.highlightAlpha)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(1, size.height - 1.5),
      Offset(size.width - 1, size.height - 1.5),
      Paint()
        ..color = (lens ? colors.lensNeutral : colors.shadow).withValues(alpha: lens ? .14 : colors.contactAlpha)
        ..strokeWidth = 1,
    );
    final top = Rect.fromLTWH(0, 1, size.width, 1);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            colors.highlight.withValues(alpha: colors.specularAlpha),
            Colors.transparent,
          ],
          stops: const [0, .48, 1],
        ).createShader(top),
    );
    if (lens) {
      canvas.drawRRect(
        inner.deflate(1),
        Paint()
          ..color = colors.highlight.withValues(alpha: colors.lensInnerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassEdge old) => old.colors != colors || old.radius != radius || old.lens != lens;
}

List<BoxShadow> glassShadows(FikraPalette c, {bool lens = false}) => [
  BoxShadow(
    color: c.shadow.withValues(alpha: c.contactAlpha),
    offset: const Offset(0, 2),
    blurRadius: 5,
  ),
  BoxShadow(
    color: c.shadow.withValues(alpha: lens ? c.lensShadowAlpha : c.shadowAlpha),
    offset: Offset(0, lens ? 8 : 10),
    blurRadius: lens ? 20 : 26,
  ),
];
