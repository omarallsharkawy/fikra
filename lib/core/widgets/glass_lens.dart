import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../theme/tokens.dart';
import 'glass_edge.dart';
import 'glass_quality.dart';

/// Phase 2's optical overlay, laid above a 90%-backed Glass. No gestures,
/// animation, capture view, chromatic dispersion, or package adaptivity.
/// Impeller refracts the live backdrop. Skia without a LiquidGlassView capture
/// falls back to frosting in liquid_glass_easy itself.
class GlassLens extends ConsumerWidget {
  const GlassLens({super.key, required this.child, this.radius = FikraRadius.full});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(glassTierProvider(MediaQuery.disableAnimationsOf(context)));
    if (tier != GlassTier.optical) return child;
    final c = context.colors;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: glassShadows(c, lens: true)),
        child: CustomPaint(
          foregroundPainter: GlassEdge(c, radius, lens: true),
          child: LiquidGlassLens(
            style: LiquidGlassStyle(
              shape: LiquidGlassShape.roundedRectangle(cornerRadius: radius),
              color: c.surface.withValues(alpha: FikraPalette.lensTintAlpha),
              blur: 7,
              saturation: 1.02,
              refractionIndex: 1.02,
              dispersion: 0,
              // Our static edge painter provides the recipe's neutral rim.
              specular: const LiquidGlassLight.specular(thickness: 0),
            ),
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
    );
  }
}
