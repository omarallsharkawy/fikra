import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'glass.dart';

class FikraChip extends StatelessWidget {
  const FikraChip({super.key, required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: onTap == null ? null : selected,
      minTarget: onTap != null,
      child: Container(
        height: onTap == null ? 30 : 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: selected ? context.colors.selectedGradient : null,
          color: selected ? null : context.colors.glassHighlight,
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: selected ? null : Border.all(color: context.colors.border, width: FikraSpace.hairline),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: context.text.chip.copyWith(
              color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control: the selected pill slides with the smooth spring
/// (instantly under Remove animations). Each segment is a 48 dp target.
class SegmentedPill extends StatefulWidget {
  const SegmentedPill({super.key, required this.options, required this.selected, required this.onChanged});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  State<SegmentedPill> createState() => _SegmentedPillState();
}

class _SegmentedPillState extends State<SegmentedPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.selected.toDouble());

  @override
  void didUpdateWidget(covariant SegmentedPill old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final target = widget.selected.toDouble();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = target;
    } else {
      _c.animateWith(SpringSimulation(FikraSprings.smooth, _c.value, target, _c.velocity));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.full,
      padding: const EdgeInsets.all(4),
      height: Pressable.minTargetSize + 10,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / widget.options.length;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Positioned(
                  left: rtl ? null : _c.value * w,
                  right: rtl ? _c.value * w : null,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: context.colors.selectedGradient,
                      borderRadius: BorderRadius.all(Radius.circular(FikraRadius.full)),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < widget.options.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == widget.selected,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(i),
                            child: Center(
                              child: Text(
                                widget.options[i],
                                // Follows the pill, so a label is never light-on-light mid-slide.
                                style: context.text.chip.copyWith(
                                  color: Color.lerp(
                                    context.colors.textSecondary,
                                    context.colors.textOnSelected,
                                    (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
