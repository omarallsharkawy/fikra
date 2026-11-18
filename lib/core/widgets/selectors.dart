import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../motion/pressable.dart';
import '../motion/rolling_text.dart';
import '../theme/tokens.dart';

import 'solid_surface.dart';

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
        constraints: BoxConstraints(minHeight: onTap == null ? 30 : 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.colors.selected : context.colors.chip,
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: selected ? null : Border.all(color: context.colors.line, width: FikraSpace.hairline),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: context.text.chip.copyWith(color: selected ? context.colors.accent : context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Segmented control: the selected pill slides with the smooth spring
/// (instantly under Remove animations). Each segment is at least a 48 dp target.
class SegmentedPill extends StatefulWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabels,
    this.segmentKeys,
    this.height,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Read by TalkBack instead of the visible option text (e.g. "Suggestions, 3").
  final List<String>? semanticLabels;
  final List<Key>? segmentKeys;

  /// Fixed outer height when a floating dock reserves an exact extent; when
  /// omitted, defaults to 58 dp at 1.0x and grows up to two lines at large text.
  final double? height;

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
    final fixedHeight = widget.height;
    return SolidSurface(
      radius: FikraRadius.full,
      padding: const EdgeInsets.all(4),
      height: fixedHeight,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / widget.options.length;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final textScaler = MediaQuery.textScalerOf(context);
          final canWrap = fixedHeight == null && textScaler.scale(1.0) > 1.0;
          final horizontalPad = canWrap ? 4.0 : 8.0;
          final maxLines = canWrap ? 2 : 1;

          Widget stack = Stack(
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
                      color: context.colors.selected,
                      borderRadius: const BorderRadius.all(Radius.circular(FikraRadius.full)),
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
                          key: widget.segmentKeys?[i],
                          button: true,
                          selected: i == widget.selected,
                          label: widget.semanticLabels?[i],
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(i),
                            child: Center(
                              child: ExcludeSemantics(
                                excluding: widget.semanticLabels != null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                                  child: RollingText(
                                    widget.options[i],
                                    textAlign: canWrap ? TextAlign.center : null,
                                    maxLines: maxLines,
                                    overflow: TextOverflow.ellipsis,
                                    // Follows the pill, so a label is never light-on-light mid-slide.
                                    style: context.text.chip.copyWith(
                                      color: Color.lerp(
                                        context.colors.textSecondary,
                                        context.colors.accent,
                                        (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
                                      ),
                                    ),
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

          if (fixedHeight != null) return stack;
          final minInner = math.max(Pressable.minTargetSize, Pressable.minTargetSize + 2 - 2 * FikraSpace.hairline);
          var innerHeight = minInner;
          if (canWrap) {
            final labelStyle = DefaultTextStyle.of(context).style.merge(context.text.chip);
            final locale = Localizations.maybeLocaleOf(context);
            final maxTextWidth = math.max(0.0, w - horizontalPad * 2);
            for (final opt in widget.options) {
              final painter = TextPainter(
                text: TextSpan(text: opt, style: labelStyle),
                textAlign: TextAlign.center,
                textDirection: Directionality.of(context),
                textScaler: textScaler,
                locale: locale,
                maxLines: 2,
                ellipsis: '…',
              )..layout(maxWidth: maxTextWidth);
              innerHeight = math.max(innerHeight, painter.height.ceilToDouble() + 12);
              painter.dispose();
            }
          }
          return SizedBox(height: innerHeight, child: stack);
        },
      ),
    );
  }
}
