import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Paints a soft breathing ring behind [child] while [active] is true.
///
/// Honors Reduce Motion (draws a static ring with no ticker) and [TickerMode]
/// (stops its ticker whenever hidden or offstage). Isolated in a [RepaintBoundary].
class RecordingPulse extends StatefulWidget {
  const RecordingPulse({
    super.key,
    required this.active,
    required this.color,
    required this.child,
    this.maxExpand = FikraMotion.pulseExpand,
  });

  final bool active;
  final Color color;
  final Widget child;
  final double maxExpand;

  @override
  State<RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<RecordingPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: FikraMotion.pulse);

  void _sync() {
    final shouldAnimate = widget.active && !FikraMotion.reduced(context) && TickerMode.valuesOf(context).enabled;
    if (shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant RecordingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final reduced = FikraMotion.reduced(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PulseRingPainter(
          animation: reduced ? const AlwaysStoppedAnimation(0.5) : _controller,
          color: widget.color,
          maxExpand: widget.maxExpand,
          reduced: reduced,
        ),
        child: widget.child,
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({required this.animation, required this.color, required this.maxExpand, required this.reduced})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double maxExpand;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final baseRadius = math.min(size.width, size.height) / 2;
    if (baseRadius <= 0) return;
    final t = reduced ? 0.6 : FikraMotion.pulseCurve.transform(animation.value);
    final radius = baseRadius + maxExpand * (0.35 + 0.65 * t);
    final alpha = reduced ? 0.22 : (0.28 - 0.16 * t);
    final fill = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = color.withValues(alpha: (alpha + 0.12).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.maxExpand != maxExpand ||
      oldDelegate.reduced != reduced ||
      oldDelegate.animation != animation;
}
