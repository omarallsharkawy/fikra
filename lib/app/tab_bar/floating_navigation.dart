import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
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
              onSelect: (index, reselect) {
                if (!keyboard) onSelect(index + 1, reselect);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        RepaintBoundary(
          child: _NavAddButton(
            selected: branch == 0,
            enabled: !keyboard,
            semanticLabel: context.l10n.navAdd,
            onTap: () => onSelect(0, branch == 0),
          ),
        ),
      ],
    );

    return IgnorePointer(
      ignoring: keyboard,
      child: ExcludeSemantics(
        excluding: keyboard,
        child: ExcludeFocus(
          excluding: keyboard,
          child: AnimatedOpacity(
            opacity: keyboard ? 0 : 1,
            duration: const Duration(milliseconds: 100),
            child: AnimatedSlide(
              offset: keyboard && !FikraMotion.reduced(context) ? const Offset(0, .18) : Offset.zero,
              duration: const Duration(milliseconds: 100),
              child: GlassVisibility(
                visible: !keyboard,
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
        ),
      ),
    );
  }
}

class _NavAddButton extends StatefulWidget {
  const _NavAddButton({
    required this.selected,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });
  final bool selected;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_NavAddButton> createState() => _NavAddButtonState();
}

class _NavAddButtonState extends State<_NavAddButton> {
  bool _focused = false;

  @override
  void didUpdateWidget(_NavAddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _focused) _focused = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (focused) {
        final next = focused && widget.enabled;
        if (_focused != next) setState(() => _focused = next);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: Pressable(
        key: const ValueKey('nav-add'),
        onTap: widget.enabled ? widget.onTap : null,
        selected: widget.selected,
        semanticLabel: widget.semanticLabel,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.brandBlue,
            border: Border.all(
              color: _focused ? c.accent : c.rim.withValues(alpha: c.rimAlpha),
              width: _focused ? 2.5 : 1,
            ),
            boxShadow: glassShadows(c),
          ),
          // Selected: an on-accent ring set 4 dp inside the edge, so it reads apart from the rim;
          // an accent ring would vanish into the brand-blue fill.
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: widget.selected
                  ? Border.all(color: c.onBrandBlue.withValues(alpha: .9), width: 1.5)
                  : _focused
                  ? Border.all(color: c.onBrandBlue.withValues(alpha: .9), width: 1.5)
                  : null,
            ),
            child: Center(child: Icon(Icons.add_rounded, size: 28, color: c.onBrandBlue)),
          ),
        ),
      ),
    );
  }
}
