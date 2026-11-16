import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'solid_surface.dart';

/// Bottom sheet shell: top radius 38, handle, title, fit to content.
///
/// A [tall] sheet takes up to 90 % of the height above the bottom safe area
/// (less while the keyboard is open), keeps its content above that safe area,
/// and gives [builder] the bounded height instead of a scroll view, so the
/// content can hold its own lazy list and keep a footer in view.
Future<T?> showFikraSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool tall = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Above the shell's floating navigation, which would cover the sheet's footer.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: FikraMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: FikraMotion.sheet,
            reverseDuration: FikraMotion.sheet,
            curve: FikraMotion.sheetCurve,
            reverseCurve: FikraMotion.sheetCurve,
          ),
    builder: (context) {
      final head = [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: context.colors.borderGraph, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: context.text.cardTitle),
        const SizedBox(height: 16),
      ];
      Widget shell(Widget content, {double? height, double safeBottom = 0}) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(FikraRadius.xxl)),
            border: Border(
              top: BorderSide(color: context.colors.line, width: FikraSpace.hairline),
            ),
          ),
          padding: EdgeInsets.fromLTRB(22, 12, 22, 28 + safeBottom),
          // The route's own Material is transparent and sits under this opaque
          // fill, so rows (ListTile, InkWell) need a Material above it for ink.
          child: Material(type: MaterialType.transparency, child: content),
        ),
      );
      if (!tall) {
        return shell(
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...head, builder(context)],
            ),
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, box) {
          final inset = MediaQuery.viewInsetsOf(context).bottom;
          // The footer stays above the gesture bar; the keyboard covers it.
          final safe = math.max(0.0, MediaQuery.paddingOf(context).bottom - inset);
          final cap = (box.maxHeight - safe) * 0.9 + safe;
          final height = (box.maxHeight - inset).clamp(0.0, cap);
          return shell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...head,
                Expanded(child: builder(context)),
              ],
            ),
            height: height,
            safeBottom: safe,
          );
        },
      );
    },
  );
}

/// Option row used inside sheets (rename, delete, …).
class SheetOption extends StatelessWidget {
  const SheetOption({super.key, required this.label, required this.icon, required this.onTap, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? context.colors.danger : context.colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: SolidSurface(
          radius: FikraRadius.md,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
              // A long label (or large text) wraps instead of overflowing.
              Flexible(
                child: Text(label, style: context.text.section.copyWith(color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
