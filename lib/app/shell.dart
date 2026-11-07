import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion.dart';
import '../core/motion/pressable.dart';
import '../core/theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = <(String, IconData)>[
    ('إضافة', Icons.add_circle_outline_rounded),
    ('النوتس', Icons.sticky_note_2_outlined),
    ('الروابط', Icons.hub_outlined),
    ('اسأل', Icons.chat_bubble_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(bottom: false, child: shell),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: FikraNavBar(
              items: _tabs,
              index: shell.currentIndex,
              onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass pill nav. The selected pill slides with the smooth spring.
class FikraNavBar extends StatefulWidget {
  const FikraNavBar({super.key, required this.items, required this.index, required this.onTap});
  final List<(String, IconData)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  State<FikraNavBar> createState() => _FikraNavBarState();
}

class _FikraNavBarState extends State<FikraNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());

  @override
  void didUpdateWidget(covariant FikraNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = widget.index.toDouble();
      } else {
        _c.animateWith(SpringSimulation(FikraSprings.smooth, _c.value, widget.index.toDouble(), _c.velocity));
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: FikraSpace.nav,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: context.colors.glassGradient,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: context.colors.border, width: FikraSpace.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / widget.items.length;
          // Label colors follow the sliding pill, never light-on-light mid-slide.
          Color fg(int i) => Color.lerp(
            context.colors.textSecondary,
            context.colors.textOnSelected,
            (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
          )!;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final x = _c.value * w;
                  return Positioned(
                    top: 0,
                    bottom: 0,
                    width: w,
                    left: rtl ? null : x,
                    right: rtl ? x : null,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: context.colors.selectedGradient,
                        borderRadius: BorderRadius.circular(FikraRadius.full),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: Pressable(
                          key: ValueKey('nav-$i'),
                          selected: i == widget.index,
                          onTap: () => widget.onTap(i),
                          semanticLabel: widget.items[i].$1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.items[i].$2, size: 22, color: fg(i)),
                              const SizedBox(height: 2),
                              Text(
                                widget.items[i].$1,
                                style: context.text.nav.copyWith(
                                  height: 1.2,
                                  color: fg(i),
                                  fontWeight: i == widget.index ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
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

/// All navigator elements stay in their original slots. Only the selected
/// branch paints, receives input/focus/semantics, or runs descendant tickers.
class FikraBranchContainer extends StatefulWidget {
  const FikraBranchContainer({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<FikraBranchContainer> createState() => _FikraBranchContainerState();
}

class _FikraBranchContainerState extends State<FikraBranchContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(covariant FikraBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _enter.duration = FikraMotion.reduced(context) ? FikraMotion.reducedFade : FikraMotion.enter;
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = FikraMotion.reduced(context);
    final progress = _enter.drive(CurveTween(curve: reduced ? Curves.linear : FikraMotion.enterCurve));
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: ExcludeFocus(
                excluding: i != widget.index,
                child: FadeTransition(
                  opacity: progress,
                  child: ScaleTransition(
                    scale: reduced
                        ? const AlwaysStoppedAnimation(1.0)
                        : progress.drive(Tween(begin: FikraMotion.enterScale, end: 1.0)),
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
