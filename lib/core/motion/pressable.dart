import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Plasma One spring presets (mass, stiffness, damping). All share ζ = 0.75.
abstract final class FikraSprings {
  static const smooth = SpringDescription(mass: 1, stiffness: 711.1, damping: 40);
  static const snappy = SpringDescription(mass: 1, stiffness: 1600, damping: 60);
  static const stiff = SpringDescription(mass: 1, stiffness: 2844, damping: 80);
}

/// Every pressable scales to 0.964 with the smooth spring (cards use 0.98).
/// No ripple. Disabled under Reduce Motion.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.964,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _to(double target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
      return;
    }
    _c.animateWith(SpringSimulation(FikraSprings.smooth, _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _to(widget.pressedScale) : null,
        onTapUp: _enabled ? (_) => _to(1) : null,
        onTapCancel: _enabled ? () => _to(1) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.scale(scale: _c.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
