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
    this.selected,
    this.minTarget = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  /// When set, TalkBack reads this instead of the child's text (no double reading).
  final String? semanticLabel;

  /// Exposed to TalkBack for tabs / segments / graph nodes.
  final bool? selected;

  /// Grow the hit area to Android's 48×48 dp minimum around a smaller visual.
  final bool minTarget;

  static const minTargetSize = 48.0;

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
    Widget child = AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(scale: _c.value, child: child),
      child: widget.child,
    );
    if (widget.minTarget) {
      child = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: Pressable.minTargetSize, minHeight: Pressable.minTargetSize),
        child: Align(widthFactor: 1, heightFactor: 1, child: child),
      );
    }
    // Labelled pressables are controls even when disabled; unlabelled ones
    // with no handler (e.g. a read-only chip) are plain content.
    final isControl = _enabled || widget.semanticLabel != null;
    return Semantics(
      button: isControl,
      enabled: isControl ? _enabled : null,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _to(widget.pressedScale) : null,
        onTapUp: _enabled ? (_) => _to(1) : null,
        onTapCancel: _enabled ? () => _to(1) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: child,
      ),
    );
  }
}
