import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Glass surface: gradient + hairline border (Figma "Gradient/Glass surface").
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = FikraRadius.lg,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.borderWidth = FikraSpace.hairline,
    this.gradient,
    this.color,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: color == null ? (gradient ?? context.colors.glassGradient) : null,
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? context.colors.border, width: borderWidth),
      ),
      child: child,
    );
  }
}
