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
    required this.position,
    this.iconOnly = false,
    required this.index,
    required this.hover,
    required this.onActivate,
    this.shrink = 0,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Animation<double> position;
  final bool iconOnly;
  final int index;
  final ValueListenable<int?> hover;
  final VoidCallback onActivate;
  final double shrink;

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
          final s = shrink.clamp(0.0, 1.0);
          final factor = (1 - s).clamp(0.0, 1.0);
          final labelOpacity = (1 - s * 1.6).clamp(0.0, 1.0);
          return AnimatedBuilder(
            animation: position,
            builder: (context, _) {
              final amount = hovered == index ? 1.0 : (1 - (position.value - index).abs()).clamp(0.0, 1.0);
              final color = Color.lerp(context.colors.textSecondary, context.colors.accent, amount)!;
              final filled = switch (icon) {
                Icons.home_outlined => Icons.home_rounded,
                Icons.hub_outlined => Icons.hub_rounded,
                Icons.chat_bubble_outline_rounded => Icons.chat_bubble_rounded,
                Icons.person_outline_rounded => Icons.person_rounded,
                _ => icon,
              };
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: hovered == index && !FikraMotion.reduced(context) ? 1.13 : 1,
                    child: Icon(selected ? filled : icon, size: 22, color: color),
                  ),
                  if (!iconOnly)
                    ClipRect(
                      clipBehavior: factor < 1 ? Clip.hardEdge : Clip.none,
                      child: Align(
                        heightFactor: factor,
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                              style: context.text.nav.copyWith(
                                fontSize: 12,
                                height: 1.35,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}
