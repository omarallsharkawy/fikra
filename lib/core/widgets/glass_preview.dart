import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'glass.dart';
import 'glass_lens.dart';
import 'glass_quality.dart';

/// Opt-in review/measurement surface. Never available in release product UI.
final glassPreviewEnabledProvider = Provider<bool>((ref) => false);

class GlassDebugOverlay extends ConsumerWidget {
  const GlassDebugOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode || !ref.watch(glassPreviewEnabledProvider)) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Positioned(left: 24, right: 24, bottom: 130, child: IgnorePointer(child: GlassReviewPanel())),
      ],
    );
  }
}

/// Same stationary geometry for every tier. Optical adds the lens on the
/// backed bar, so its 20% tint is never used as a reading surface on its own.
class GlassReviewPanel extends ConsumerWidget {
  const GlassReviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(glassTierProvider(MediaQuery.disableAnimationsOf(context)));
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 12,
            bottom: 12,
            child: Glass(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tier.name, style: context.text.meta),
              ),
            ),
          ),
          if (tier == GlassTier.optical)
            Positioned(
              top: 6,
              bottom: 6,
              left: 72,
              right: 12,
              child: GlassLens(
                child: Center(child: Text('فكرة', style: context.text.section)),
              ),
            ),
        ],
      ),
    );
  }
}
