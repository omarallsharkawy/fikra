import 'smart_text.dart';

import 'package:flutter/material.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'solid_surface.dart';

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
    this.growForText = false,
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
    this.growForText = false,
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
    this.growForText = false,
  }) : style = FikraButtonStyle.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FikraButtonStyle style;
  final bool expand;
  final bool loading;
  final double horizontalPadding;
  final int? maxLines;

  /// Preserve the minimum target while allowing large text to wrap in full.
  final bool growForText;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Color color, Color fg, TextStyle text) = switch (style) {
      FikraButtonStyle.primary => (context.colors.brandLime, context.colors.onBrandLime, context.text.button),
      FikraButtonStyle.secondary => (context.colors.surface, context.colors.textPrimary, context.text.section),
      FikraButtonStyle.danger => (context.colors.dangerBg, context.colors.danger, context.text.section),
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
          child: SmartText(
            label,
            style: text.copyWith(color: fg),
            overflow: growForText ? TextOverflow.visible : TextOverflow.ellipsis,
            maxLines: growForText ? maxLines : (maxLines ?? 1),
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
          constraints: const BoxConstraints(minHeight: FikraSpace.button),
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: growForText ? 12 : 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(FikraRadius.md),
            border: style == FikraButtonStyle.secondary ? Border.all(color: context.colors.line, width: 1) : null,
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

/// Round solid icon button (back, more, zoom…). [label] is read by screen
/// readers; the hit area is at least 48 dp whatever the visual [size].
class FikraIconButton extends StatelessWidget {
  const FikraIconButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 44});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: SolidSurface(
        radius: FikraRadius.full,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        child: Icon(icon, size: size * 0.48),
      ),
    );
  }
}
