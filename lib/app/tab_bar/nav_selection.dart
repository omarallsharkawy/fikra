import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Only paint transforms listen to the spring; tab geometry stays fixed.
class NavSelection extends StatelessWidget {
  const NavSelection({
    super.key,
    required this.position,
    required this.pulse,
    required this.width,
    required this.height,
    required this.count,
  });
  final Animation<double> position;
  final Animation<double> pulse;
  final double width;
  final double height;
  final int count;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 4,
    top: 4,
    width: width,
    height: height,
    child: AnimatedBuilder(
      animation: position,
      child: FadeTransition(
        opacity: pulse.drive(Tween(begin: 1.0, end: .32)),
        child: DecoratedBox(
          key: const ValueKey('nav-selected-pill'),
          decoration: BoxDecoration(
            color: context.colors.selected.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
      builder: (context, child) => Transform.translate(
        offset: Offset(
          (Directionality.of(context) == TextDirection.rtl ? count - 1 - position.value : position.value) * width,
          0,
        ),
        child: child,
      ),
    ),
  );
}
