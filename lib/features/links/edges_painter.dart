part of 'links_screen.dart';

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.links,
    required this.pos,
    required this.selected,
    required this.edgeColor,
    required this.light,
  });
  final Color edgeColor;
  final bool light;
  final List<GraphLink> links;
  final Map<String, GraphPosition> pos;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in links) {
      final a = _rect(pos[l.sourceId]!).center;
      final b = _rect(pos[l.targetId]!).center;
      final active = selected != null && (l.sourceId == selected || l.targetId == selected);
      final dim = selected != null && !active;
      var opacity = 1.0;
      if (dim) {
        opacity = light ? 0.35 : 0.12;
      } else if (!active) {
        opacity = light ? 0.8 + l.strength * 0.2 : 0.35 + l.strength * 0.4;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 2.2 : 1 + l.strength * 1.5
        ..color = edgeColor.withValues(alpha: opacity);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final bend = a.dy == b.dy ? -40.0 : 0.0; // same-row links arc upward
      final ctrl = Offset(mid.dx, mid.dy + bend);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.links != links ||
      old.selected != selected ||
      old.pos != pos ||
      old.edgeColor != edgeColor ||
      old.light != light;
}
