import '../../core/widgets/smart_text.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';

class TabLabel extends StatefulWidget {
  const TabLabel({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.position,
    this.iconOnly = false,
    this.enabled = true,
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
  final bool enabled;
  final int index;
  final ValueListenable<int?> hover;
  final VoidCallback onActivate;
  final double shrink;

  @override
  State<TabLabel> createState() => _TabLabelState();
}

class _TabLabelState extends State<TabLabel> {
  bool _focused = false;

  @override
  void didUpdateWidget(TabLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _focused) _focused = false;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.enabled,
    selected: widget.selected,
    label: widget.label,
    onTap: widget.enabled ? widget.onActivate : null,
    excludeSemantics: true,
    child: FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (focused) {
        final next = focused && widget.enabled;
        if (_focused != next) setState(() => _focused = next);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onActivate();
            return null;
          },
        ),
      },
      child: DecoratedBox(
        decoration: _focused && widget.enabled
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(FikraRadius.full),
                border: Border.all(color: context.colors.accent, width: 2),
              )
            : const BoxDecoration(),
        child: ValueListenableBuilder<int?>(
          valueListenable: widget.hover,
          builder: (context, hovered, _) {
            final s = widget.shrink.clamp(0.0, 1.0);
            final factor = (1 - s).clamp(0.0, 1.0);
            final labelOpacity = (1 - s * 1.6).clamp(0.0, 1.0);
            return AnimatedBuilder(
              animation: widget.position,
              builder: (context, _) {
                final amount = hovered == widget.index
                    ? 1.0
                    : (1 - (widget.position.value - widget.index).abs()).clamp(0.0, 1.0);
                final color = Color.lerp(context.colors.textSecondary, context.colors.accent, amount)!;
                final filled = switch (widget.icon) {
                  Icons.home_outlined => Icons.home_rounded,
                  Icons.hub_outlined => Icons.hub_rounded,
                  Icons.chat_bubble_outline_rounded => Icons.chat_bubble_rounded,
                  Icons.person_outline_rounded => Icons.person_rounded,
                  _ => widget.icon,
                };
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: hovered == widget.index && !FikraMotion.reduced(context) ? 1.13 : 1,
                      child: Icon(widget.selected ? filled : widget.icon, size: 22, color: color),
                    ),
                    if (!widget.iconOnly)
                      ClipRect(
                        clipBehavior: factor < 1 ? Clip.hardEdge : Clip.none,
                        child: Align(
                          heightFactor: factor,
                          child: Opacity(
                            opacity: labelOpacity,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 2, 0),
                              child: SmartText(
                                widget.label,
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
    ),
  );
}
