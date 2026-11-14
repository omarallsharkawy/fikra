part of 'links_screen.dart';

/// The viewer's zoom range. Programmatic moves stay inside it so the buttons
/// and pinch never start outside their own clamp.
const _minScale = 0.5, _maxScale = 2.5;

/// Uniform x/y/z scale: `getMaxScaleOnAxis`, which [InteractiveViewer] uses
/// to clamp pinches, must read the same scale the canvas shows.
Matrix4 _scaled(double tx, double ty, double s) => Matrix4.translationValues(tx, ty, 0)..scaleByDouble(s, s, s, 1);

double _scaleOf(Matrix4 m) => m.entry(0, 0).abs();

extension _LinksJump on _LinksScreenState {
  /// Fit the frame when it fits at the minimum zoom; otherwise centre each
  /// axis that fits and show the frame's reading-start edge and header.
  void _fitFrame(GraphFrame frame) {
    _setState(() => _selected = null);
    final rect = _rect(frame.bounds).inflate(20);
    final view = _viewportSize;
    final s = math.min(view.width / rect.width, view.height / rect.height).clamp(_minScale, _maxScale);
    double axis(double start, double extent, double size, {required bool fromEnd}) {
      if (extent * s <= size) return size / 2 - (start + extent / 2) * s;
      return fromEnd ? size - (start + extent) * s : -start * s;
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    _moveViewport(
      _scaled(
        axis(rect.left, rect.width, view.width, fromEnd: rtl),
        axis(rect.top, rect.height, view.height, fromEnd: false),
        s,
      ),
    );
  }

  Matrix4 _atCentre(Offset point, double scale) =>
      _scaled(_viewportSize.width / 2 - point.dx * scale, _viewportSize.height / 2 - point.dy * scale, scale);

  void _centreViewport(Offset point) => _moveViewport(_atCentre(point, _scaleOf(_tc.value)));

  void _centreViewportImmediately(Offset point) {
    _travel.stop();
    _tc.value = _atCentre(point, _scaleOf(_tc.value));
  }

  void _moveViewport(Matrix4 target) {
    _travel.stop();
    if (FikraMotion.reduced(context)) {
      _tc.value = target;
      return;
    }
    _travelValue = Matrix4Tween(begin: _tc.value.clone(), end: target);
    _travel.forward(from: 0);
  }

  /// RTL canvases are mirrored against their width. When the width changes
  /// (a fold, or a wider row), move the view by the same amount so content
  /// stays anchored at the reading start instead of jumping sideways.
  void _keepReadingStart(GraphLayout? previous, GraphLayout next) {
    if (previous == null || !next.rtl || !previous.rtl || previous.width == next.width) return;
    if (previous.frames.isEmpty && next.frames.isEmpty) return; // Legacy, frameless width changes re-home.
    _travel.stop();
    final dx = (previous.width - next.width) * _scaleOf(_tc.value);
    _tc.value = Matrix4.translationValues(dx, 0, 0)..multiply(_tc.value);
  }
}
