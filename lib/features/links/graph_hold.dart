part of 'links_screen.dart';

/// Raw pointer tracking never claims the scale gesture arena. Measure slop in
/// screen pixels, so zoom does not change the movement needed to cancel a hold.
class _GraphHold extends StatefulWidget {
  const _GraphHold({
    required this.onHold,
    required this.onTap,
    required this.registerCancel,
    required this.canHold,
    required this.builder,
  });
  final VoidCallback onHold, onTap;
  final void Function(VoidCallback?) registerCancel;
  final bool Function() canHold;
  final Widget Function(VoidCallback tap, VoidCallback semanticHold) builder;

  @override
  State<_GraphHold> createState() => _GraphHoldState();
}

class _GraphHoldState extends State<_GraphHold> {
  Timer? _timer;
  Offset? _origin;
  bool _held = false;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _cancel();
      _held = false;
      _origin = e.position;
      widget.registerCancel(_cancel);
      if (!widget.canHold()) return;
      _timer = Timer(kLongPressTimeout, () {
        if (!mounted || !widget.canHold()) return;
        _held = true;
        widget.onHold();
      });
    },
    onPointerMove: (e) {
      if (_origin != null &&
          (e.position - _origin!).distance > computeHitSlop(e.kind, MediaQuery.maybeGestureSettingsOf(context))) {
        _cancel();
      }
    },
    onPointerUp: (_) => _cancel(),
    onPointerCancel: (_) => _cancel(),
    child: widget.builder(() {
      if (!_held) widget.onTap();
      _held = false;
    }, widget.onHold),
  );
}
