import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'glass_edge.dart';
import 'glass_quality.dart';
import 'glass_watchdog.dart';

/// Explicit visibility scope for mounted [Glass] widgets that stay in the tree
/// while hidden (for example, floating navigation hidden by the keyboard).
class GlassVisibility extends InheritedWidget {
  const GlassVisibility({super.key, required this.visible, required super.child});
  final bool visible;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassVisibility>()?.visible ?? true;

  @override
  bool updateShouldNotify(GlassVisibility oldWidget) => visible != oldWidget.visible;
}

/// Floating tab-bar chrome only. Optical is a frosted backing with a separate
/// [GlassLens] above it (see glass_lens.dart); reading content uses SolidSurface.
/// Wrap non-overlapping siblings in BackdropGroup to share their backdrop pass.
class Glass extends ConsumerStatefulWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = FikraRadius.full,
    this.padding = const EdgeInsets.all(12),
    this.visible = true,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool visible;

  static const blurSigma = 16.0;

  @override
  ConsumerState<Glass> createState() => _GlassState();
}

class _GlassState extends ConsumerState<Glass> {
  GlassWatchdog? _watchdog;

  void _syncWatchdog(GlassTier tier) {
    final active =
        tier != GlassTier.solid &&
        widget.visible &&
        GlassVisibility.of(context) &&
        !(MediaQuery.maybeHighContrastOf(context) ?? false) &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (active) {
      final GlassWatchdog watchdog = _watchdog ?? ref.read(glassWatchdogProvider.notifier);
      _watchdog = watchdog;
      watchdog.show(this, View.of(context).display.refreshRate);
    } else {
      _watchdog?.hide(this);
    }
  }

  @override
  void dispose() {
    _watchdog?.hide(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = effectiveGlassTier(context, ref);
    _syncWatchdog(tier);
    final c = context.colors;
    final borderRadius = BorderRadius.circular(widget.radius);
    Widget body = ColoredBox(
      color: c.surface.withValues(alpha: tier == GlassTier.solid ? 1 : c.glassBackingAlpha),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    if (tier != GlassTier.solid) {
      body = BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: Glass.blurSigma, sigmaY: Glass.blurSigma),
        child: body,
      );
    }
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: glassShadows(c)),
        child: CustomPaint(
          foregroundPainter: GlassEdge(c, widget.radius),
          child: ClipRRect(borderRadius: borderRadius, child: body),
        ),
      ),
    );
  }
}
