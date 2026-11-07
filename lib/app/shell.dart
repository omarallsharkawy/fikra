import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';

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
      decoration: const BoxDecoration(gradient: FikraColors.screenGradient),
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
        gradient: FikraColors.glassGradient,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: FikraColors.border, width: FikraSpace.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / widget.items.length;
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
                        gradient: FikraColors.selectedGradient,
                        borderRadius: BorderRadius.circular(FikraRadius.full),
                      ),
                    ),
                  );
                },
              ),
              Row(
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
                            Icon(
                              widget.items[i].$2,
                              size: 22,
                              color: i == widget.index ? FikraColors.textPrimary : FikraColors.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.items[i].$1,
                              style: FikraText.nav.copyWith(
                                height: 1.2,
                                color: i == widget.index ? FikraColors.textPrimary : FikraColors.textSecondary,
                                fontWeight: i == widget.index ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
