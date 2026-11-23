import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Opaque reading content. Never blurs or creates an offscreen layer.
class SolidSurface extends StatelessWidget {
  const SolidSurface({
    super.key,
    required this.child,
    this.radius = FikraRadius.lg,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.borderWidth = FikraSpace.hairline,
    this.color,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    assert(color == null || color!.a == 1, 'Reading surfaces must be opaque');
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? context.colors.line, width: borderWidth),
      ),
      child: child,
    );
  }
}
