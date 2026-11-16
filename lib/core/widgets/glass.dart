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
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<Glass> createState() => _GlassState();
}

class _GlassState extends ConsumerState<Glass> {
  GlassWatchdog? _watchdog;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchdog ??= ref.read(glassWatchdogProvider.notifier);
    if (TickerMode.valuesOf(context).enabled && (ModalRoute.isCurrentOf(context) ?? true)) {
      _watchdog!.show(this, View.of(context).display.refreshRate);
    } else {
      _watchdog!.hide(this);
    }
  }

  @override
  void dispose() {
    _watchdog?.hide(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(glassTierProvider(MediaQuery.disableAnimationsOf(context)));
    final c = context.colors;
    Widget body = ColoredBox(
      color: c.surface.withValues(alpha: tier == GlassTier.solid ? 1 : FikraPalette.glassBackingAlpha),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    if (tier != GlassTier.solid) {
      body = BackdropFilter.grouped(filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: body);
    }
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), boxShadow: glassShadows(c)),
        child: CustomPaint(
          foregroundPainter: GlassEdge(c, widget.radius),
          child: ClipRRect(borderRadius: BorderRadius.circular(widget.radius), child: body),
        ),
      ),
    );
  }
}
