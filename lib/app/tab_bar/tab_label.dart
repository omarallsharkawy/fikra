import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';

class TabLabel extends StatelessWidget {
  const TabLabel({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.index,
    required this.hover,
    required this.onActivate,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final int index;
  final ValueListenable<int?> hover;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    onTap: onActivate,
    excludeSemantics: true,
    child: FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onActivate();
            return null;
          },
        ),
      },
      child: ValueListenableBuilder<int?>(
        valueListenable: hover,
        builder: (context, hovered, _) {
          final active = hovered == index || selected;
          final color = active ? context.colors.accent : context.colors.textSecondary;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: hovered == index && !FikraMotion.reduced(context) ? 1.13 : 1,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
                  style: context.text.nav.copyWith(
                    height: 1.35,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
