import 'package:flutter/material.dart';

import '../core/motion/motion.dart';

/// Navigators keep their slots and cached screens. Only these paint leaves
/// animate; offstage and outgoing screens have disabled descendant tickers.
class FikraBranchContainer extends StatelessWidget {
  const FikraBranchContainer({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < children.length; i++)
        _BranchTransition(key: ValueKey(i), index: i, active: i == index, child: children[i]),
    ],
  );
}

class _BranchTransition extends StatefulWidget {
  const _BranchTransition({super.key, required this.index, required this.active, required this.child});
  final int index;
  final bool active;
  final Widget child;

  @override
  State<_BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<_BranchTransition> with SingleTickerProviderStateMixin {
  late final _opacity = AnimationController(vsync: this, value: widget.active ? 1 : 0);
  late final _scale = _opacity.drive(Tween(begin: .98, end: 1.0));

  void _update() {
    final target = widget.active ? 1.0 : 0.0;
    if (FikraMotion.reduced(context)) {
      _opacity.value = target;
    } else {
      _opacity.animateTo(
        target,
        duration: Duration(milliseconds: widget.active ? 220 : 110),
        curve: Curves.decelerate,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _BranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _update();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FikraMotion.reduced(context)) _opacity.value = widget.active ? 1 : 0;
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = FikraMotion.reduced(context);
    return AnimatedBuilder(
      animation: _opacity,
      child: IgnorePointer(
        ignoring: !widget.active,
        child: ExcludeSemantics(
          excluding: !widget.active,
          child: ExcludeFocus(
            excluding: !widget.active,
            child: TickerMode(
              enabled: widget.active,
              child: RepaintBoundary(child: widget.child),
            ),
          ),
        ),
      ),
      builder: (context, child) => Offstage(
        offstage: !widget.active && _opacity.value == 0,
        child: FadeTransition(
          key: ValueKey('branch-opacity-${widget.index}'),
          opacity: _opacity,
          child: ScaleTransition(
            key: ValueKey('branch-scale-${widget.index}'),
            scale: reduced || !widget.active ? const AlwaysStoppedAnimation(1.0) : _scale,
            child: child,
          ),
        ),
      ),
    );
  }
}
