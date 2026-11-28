import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';

/// Owner-approved floating glass variant, preserving existing branch identities.
class ProductNavigation extends StatefulWidget {
  const ProductNavigation({super.key, required this.branch, required this.onSelect, this.hidden = false});
  final int branch;
  final bool hidden;
  final void Function(int branch, bool reselect) onSelect;
  static double barHeight(BuildContext c) {
    final scale = MediaQuery.textScalerOf(c).scale(1);
    return scale <= 1 ? 68 : 40 + 38 * scale;
  }

  @override
  State<ProductNavigation> createState() => _ProductNavigationState();
}

class _ProductNavigationState extends State<ProductNavigation> {
  int? _pressed;
  @override
  Widget build(BuildContext context) {
    if (widget.hidden) return const SizedBox.shrink();
    final c = context.rd;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motion = reduced ? Duration.zero : const Duration(milliseconds: 320);
    final height = ProductNavigation.barHeight(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 14 - 68) / 4;
        final selected = switch (widget.branch) {
          1 => 0,
          2 => 1,
          3 => 3,
          4 => 4,
          _ => -1,
        };
        double offset(int index) => index < 2 ? index * width : 2 * width + 68 + (index - 3) * width;
        final x = selected < 0 ? 0.0 : 7 + offset(selected);
        Widget tab(int id, int index, String label, String icon) => Expanded(
          child: Semantics(
            selected: widget.branch == id,
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: () => widget.onSelect(id, widget.branch == id),
            child: Tooltip(
              message: label,
              child: InkWell(
                key: ValueKey('nav-$index'),
                borderRadius: BorderRadius.circular(24),
                onTap: () => widget.onSelect(id, widget.branch == id),
                onTapDown: (_) => setState(() => _pressed = id),
                onTapCancel: () => setState(() => _pressed = null),
                onTapUp: (_) => setState(() => _pressed = null),
                child: AnimatedScale(
                  scale: _pressed == id ? 0.94 : 1,
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 44, minHeight: height - 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: widget.branch == id ? -2 : 0),
                          duration: motion,
                          curve: const Cubic(.2, .9, .2, 1),
                          builder: (_, value, child) => Transform.translate(offset: Offset(0, value), child: child),
                          child: RdIcon(icon, color: widget.branch == id ? c.purple : c.muted),
                        ),
                        const SizedBox(height: 2),
                        RdText(
                          label,
                          size: 11.5,
                          weight: widget.branch == id ? FontWeight.w600 : FontWeight.w400,
                          color: widget.branch == id ? c.text : c.muted,
                          align: TextAlign.center,
                          lines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        return SizedBox(
          height: height + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: c.dark ? 0.38 : 0.14),
                        offset: const Offset(0, 8),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface.withValues(alpha: .58),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: c.dark ? 0.13 : 0.8)),
                        ),
                        child: Stack(
                          children: [
                            if (selected >= 0)
                              AnimatedPositionedDirectional(
                                duration: motion,
                                curve: const Cubic(.2, .9, .2, 1),
                                start: x,
                                top: 9,
                                width: width - 4,
                                height: height - 20,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c.purpleSoft,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                              child: Row(
                                key: const ValueKey('product-navigation'),
                                children: [
                                  tab(1, 0, context.l10n.rdHome, 'home'),
                                  tab(2, 1, context.l10n.rdMap, 'map'),
                                  const SizedBox(width: 68),
                                  tab(3, 2, context.l10n.rdAsk, 'ask'),
                                  tab(4, 3, context.l10n.rdMe, 'me'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 3,
                left: (box.maxWidth - 56) / 2,
                child: AnimatedScale(
                  scale: _pressed == 0 ? 0.94 : 1,
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
                  child: Material(
                    color: c.purple,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: .2),
                    child: InkWell(
                      key: const ValueKey('nav-add'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onSelect(0, widget.branch == 0),
                      onTapDown: (_) => setState(() => _pressed = 0),
                      onTapUp: (_) => setState(() => _pressed = null),
                      onTapCancel: () => setState(() => _pressed = null),
                      child: SizedBox.square(
                        dimension: 56,
                        child: Semantics(
                          button: true,
                          label: context.l10n.rdStart,
                          child: Center(child: RdIcon('plus', size: 24, color: c.dark ? c.bg : Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
