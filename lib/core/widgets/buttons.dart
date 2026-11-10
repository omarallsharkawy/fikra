import 'package:flutter/material.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'glass.dart';

enum FikraButtonStyle { primary, secondary, danger }

class FikraButton extends StatelessWidget {
  const FikraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = FikraButtonStyle.primary,
    this.expand = true,
    this.loading = false,
    this.horizontalPadding = 24,
    this.maxLines,
  });

  const FikraButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.horizontalPadding = 24,
    this.maxLines,
  }) : style = FikraButtonStyle.secondary;

  const FikraButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.horizontalPadding = 24,
    this.maxLines,
  }) : style = FikraButtonStyle.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FikraButtonStyle style;
  final bool expand;
  final bool loading;
  final double horizontalPadding;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Gradient? gradient, Color? color, Color fg, TextStyle text) = switch (style) {
      FikraButtonStyle.primary => (
        context.colors.primaryGradient,
        null,
        context.colors.textOnLight,
        context.text.button,
      ),
      FikraButtonStyle.secondary => (
        context.colors.glassGradient,
        null,
        context.colors.textPrimary,
        context.text.section,
      ),
      FikraButtonStyle.danger => (null, context.colors.dangerBg, context.colors.danger, context.text.section),
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, color: fg, size: 20),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: text.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
            maxLines: maxLines,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: label,
        child: Container(
          height: FikraSpace.button,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(FikraRadius.full),
            border: style == FikraButtonStyle.secondary
                ? Border.all(color: context.colors.border, width: FikraSpace.hairline)
                : null,
          ),
          // `alignment` would make the container fill the available width,
          // so compact buttons hug their content instead.
          alignment: expand ? Alignment.center : null,
          child: content,
        ),
      ),
    );
  }
}

/// Round glass icon button (back, more, zoom…). [label] is read by screen
/// readers; the hit area is at least 48 dp whatever the visual [size].
class FikraIconButton extends StatelessWidget {
  const FikraIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.solid = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  /// Opaque background, for buttons floating over content.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: Glass(
        radius: FikraRadius.full,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        color: solid ? context.colors.glass : null,
        child: Icon(icon, size: size * 0.48),
      ),
    );
  }
}
