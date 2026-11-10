import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'glass.dart';

/// Bottom sheet shell: top radius 38, handle, title, fit to content.
Future<T?> showFikraSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
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
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.colors.screenGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(FikraRadius.xxl)),
          border: Border(
            top: BorderSide(color: context.colors.border, width: FikraSpace.hairline),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              builder(context),
            ],
          ),
        ),
      ),
    ),
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
        child: Glass(
          radius: FikraRadius.md,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
              Text(label, style: context.text.section.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
