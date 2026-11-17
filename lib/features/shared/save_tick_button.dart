import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';

/// Composer save button: check mark on the accent gradient at rest; briefly
/// morphs into a spring-driven confirmation check mark when a note is saved,
/// then returns to normal.
class SaveTickButton extends StatelessWidget {
  const SaveTickButton({
    super.key,
    required this.label,
    required this.loading,
    required this.tick,
    required this.tickActive,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final Animation<double>? tick;
  final bool tickActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = FikraMotion.reduced(context);
    final activeTap = loading || tickActive ? null : onTap;
    final visual = tickActive && tick != null
        ? RepaintBoundary(
            child: AnimatedBuilder(
              animation: tick!,
              builder: (context, _) {
                final raw = tick!.value;
                final p = raw.clamp(0.0, 1.0);
                final scale = reduced ? 1.0 : (0.86 + 0.14 * raw);
                final restingOut = (1.0 - p / 0.35).clamp(0.0, 1.0);
                final checkProgress = ((p - 0.12) / 0.88).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (p < 1)
                          Opacity(
                            opacity: 1 - p,
                            child: DecoratedBox(
                              decoration: BoxDecoration(gradient: c.addGradient, shape: BoxShape.circle),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        Opacity(
                          opacity: p,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.successBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.success, width: 1.5),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        if (restingOut > 0)
                          Opacity(
                            opacity: restingOut,
                            child: Transform.scale(
                              scale: 0.7 + 0.3 * restingOut,
                              child: Icon(Icons.check_rounded, size: 22, color: c.onAccent),
                            ),
                          ),
                        if (checkProgress > 0) SaveTickMark(progress: checkProgress, color: c.success),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: c.addGradient, shape: BoxShape.circle),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent),
                  )
                : Icon(Icons.check_rounded, size: 22, color: c.onAccent),
          );
    return Pressable(
      onTap: activeTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null && !loading && !tickActive ? 0.35 : 1,
        duration: reduced ? Duration.zero : FikraMotion.exit,
        child: visual,
      ),
    );
  }
}

/// Progressive rounded check mark drawn inside [SaveTickButton] during save confirmation.
@visibleForTesting
class SaveTickMark extends StatelessWidget {
  const SaveTickMark({super.key, required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 24,
    child: CustomPaint(
      painter: _SaveTickPainter(progress: progress, color: color),
    ),
  );
}

class _SaveTickPainter extends CustomPainter {
  const _SaveTickPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  static const _p0 = Offset(5.5, 12.5);
  static const _p1 = Offset(10.2, 17.2);
  static const _p2 = Offset(18.8, 7.6);
  static final _l1 = (_p1 - _p0).distance;
  static final _l2 = (_p2 - _p1).distance;

  @override
  void paint(Canvas canvas, Size size) {
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;
    final drawn = clamped * (_l1 + _l2);
    final firstEnd = Offset.lerp(_p0, _p1, (drawn / _l1).clamp(0.0, 1.0))!;
    final path = Path()
      ..moveTo(_p0.dx, _p0.dy)
      ..lineTo(firstEnd.dx, firstEnd.dy);
    if (drawn > _l1) {
      final secondEnd = Offset.lerp(_p1, _p2, ((drawn - _l1) / _l2).clamp(0.0, 1.0))!;
      path.lineTo(secondEnd.dx, secondEnd.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SaveTickPainter old) => old.progress != progress || old.color != color;
}
