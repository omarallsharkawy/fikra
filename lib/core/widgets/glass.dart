import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'glass_edge.dart';
import 'glass_quality.dart';
import 'glass_watchdog.dart';

/// Floating controls only. Optical is a frosted backing with a separate
/// [GlassLens] above it (see glass_lens.dart); reading content uses SolidSurface.
/// Wrap non-overlapping siblings in BackdropGroup to share their backdrop pass.
class Glass extends ConsumerStatefulWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = FikraRadius.full,
    this.borderRadius,
    this.padding = const EdgeInsets.all(12),
    this.blurEnabled = true,
  });
  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool blurEnabled;

  @override
  ConsumerState<Glass> createState() => _GlassState();
}

class _GlassState extends ConsumerState<Glass> {
  GlassWatchdog? _watchdog;

  void _syncWatchdog() {
    _watchdog ??= ref.read(glassWatchdogProvider.notifier);
    final active =
        widget.blurEnabled &&
        !(MediaQuery.maybeHighContrastOf(context) ?? false) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (active) {
      _watchdog!.show(this, View.of(context).display.refreshRate);
    } else {
      _watchdog!.hide(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWatchdog();
  }

  @override
  void didUpdateWidget(covariant Glass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blurEnabled != widget.blurEnabled) _syncWatchdog();
  }

  @override
  void dispose() {
    _watchdog?.hide(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = effectiveGlassTier(context, ref);
    final c = context.colors;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(widget.radius);
    Widget body = ColoredBox(
      color: c.surface.withValues(alpha: tier == GlassTier.solid ? 1 : FikraPalette.glassBackingAlpha),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    if (tier != GlassTier.solid) {
      body = BackdropFilter.grouped(
        enabled: widget.blurEnabled,
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: body,
      );
    }
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: glassShadows(c)),
        child: CustomPaint(
          foregroundPainter: GlassEdge(c, widget.radius, borderRadius: widget.borderRadius),
          child: ClipRRect(borderRadius: borderRadius, child: body),
        ),
      ),
    );
  }
}
