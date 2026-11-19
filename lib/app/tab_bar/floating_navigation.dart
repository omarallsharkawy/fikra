import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass_edge.dart';
import '../../l10n/localizations.dart';
import 'sliding_tab_bar.dart';

/// Branch IDs stay stable: Add owns branch 0, visible tabs own branches 1–4.
class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({
    super.key,
    required this.branch,
    required this.onSelect,
    this.keyboardOpen = false,
    this.shrink,
    this.aboveBar,
  });
  final int branch;
  final bool keyboardOpen;
  final ValueListenable<double>? shrink;
  final Widget? aboveBar;
  final void Function(int branch, bool reselect) onSelect;

  static const height = 72.0;
  static const gap = 12.0;
  static const lensOverhang = 8.0;
  static const clearance = height + gap + lensOverhang;

  /// BackdropGroup's default key is new per build: every rebuild (each tab
  /// switch) would update both filters and repaint the tab bar and capsule.
  static final _backdropKey = BackdropKey();

  @override
  Widget build(BuildContext context) {
    // From AppShell, not MediaQuery here: viewInsets changes on every frame of
    // the keyboard animation, and only the open/closed edge matters.
    final keyboard = keyboardOpen;
    final barRow = Row(
      key: const ValueKey('floating-navigation'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FikraNavBar(
              items: [
                (context.l10n.navHome, Icons.home_outlined),
                (context.l10n.navMap, Icons.hub_outlined),
                (context.l10n.navAsk, Icons.chat_bubble_outline_rounded),
                (context.l10n.navMe, Icons.person_outline_rounded),
              ],
              index: branch - 1,
              enabled: !keyboard,
              shrink: shrink,
              onSelect: (index, reselect) => onSelect(index + 1, reselect),
            ),
          ),
        ),
        const SizedBox(width: 8),
        RepaintBoundary(
          child: Pressable(
            key: const ValueKey('nav-add'),
            onTap: () => onSelect(0, branch == 0),
            selected: branch == 0,
            semanticLabel: context.l10n.navAdd,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.colors.addGradient,
                border: Border.all(color: context.colors.rim.withValues(alpha: context.colors.rimAlpha), width: 1),
                boxShadow: glassShadows(context.colors),
              ),
              // Selected: an on-accent ring set 4 dp inside the edge, so it reads apart from the rim;
              // an accent ring would vanish into the accent gradient.
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: branch == 0
                      ? Border.all(color: context.colors.onAccent.withValues(alpha: .9), width: 1.5)
                      : null,
                ),
                child: Center(child: Icon(Icons.add_rounded, size: 28, color: context.colors.onAccent)),
              ),
            ),
          ),
        ),
      ],
    );

    return IgnorePointer(
      ignoring: keyboard,
      child: ExcludeSemantics(
        excluding: keyboard,
        child: AnimatedOpacity(
          opacity: keyboard ? 0 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedSlide(
            offset: keyboard && !FikraMotion.reduced(context) ? const Offset(0, .18) : Offset.zero,
            duration: const Duration(milliseconds: 100),
            child: BackdropGroup(
              backdropKey: _backdropKey,
              child: aboveBar == null
                  ? barRow
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: aboveBar),
                        barRow,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
