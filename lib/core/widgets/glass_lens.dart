import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../theme/tokens.dart';
import 'glass_edge.dart';
import 'glass.dart';
import 'glass_quality.dart';

/// Phase 2's optical overlay, laid above a 90%-backed Glass. No gestures,
/// animation controllers, capture view, chromatic dispersion, or package adaptivity.
/// Impeller refracts the live backdrop. Skia without a LiquidGlassView capture
/// falls back to frosting in liquid_glass_easy itself.
class GlassLens extends ConsumerWidget {
  const GlassLens({super.key, required this.child, this.radius = FikraRadius.full, this.opacity = 1});
  final Widget child;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = effectiveGlassTier(context, ref);
    if (tier != GlassTier.optical) {
      // Overlapping lenses must not share the bar's backdrop key.
      return Opacity(
        opacity: opacity,
        child: BackdropGroup(
          child: Glass(radius: radius, padding: EdgeInsets.zero, child: child),
        ),
      );
    }
    final c = context.colors;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            for (final shadow in glassShadows(c, lens: true))
              shadow.copyWith(color: shadow.color.withValues(alpha: shadow.color.a * opacity)),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: GlassEdge(c, radius, lens: true, opacity: opacity),
          child: LiquidGlassLens(
            // Native shader opacity preserves backdrop refraction during fade.
            // An enclosing Opacity layer would isolate it from the live scene.
            opacity: opacity,
            style: LiquidGlassStyle(
              shape: LiquidGlassShape.roundedRectangle(cornerRadius: radius),
              color: c.surface.withValues(alpha: FikraPalette.lensTintAlpha),
              blur: 7 * opacity,
              saturation: 1.02,
              refractionIndex: 1.02,
              dispersion: 0,
              // Our static edge painter provides the recipe's neutral rim.
              specular: const LiquidGlassLight.specular(thickness: 0),
            ),
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    transform: const PearlGradientAngle(135),
                    colors: [
                      c.highlight.withValues(alpha: c.lensSheenAlpha),
                      Colors.transparent,
                      c.lensNeutral.withValues(alpha: .03),
                    ],
                    stops: const [0, .43, 1],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
