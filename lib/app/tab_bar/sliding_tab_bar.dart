import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import 'nav_selection.dart';

import 'owned_horizontal_drag.dart';

import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_lens.dart';
import 'tab_label.dart';

part 'nav_bar_visual.dart';

/// Hold duration before a stationary press engages the floating glass lens.
const kLensHoldDelay = Duration(milliseconds: 200);

/// Pointer tracking is confined to this box. Only the lens listens to its
/// pixel-position controller; branch navigators never listen to pointer moves.
class FikraNavBar extends StatefulWidget {
  const FikraNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    this.enabled = true,
    this.shrink,
  });
  final List<(String, IconData)> items;

  /// Visible tab index; -1 while Add is current.
  final int index;
  final bool enabled;
  final ValueListenable<double>? shrink;
  final void Function(int index, bool reselect) onSelect;

  @override
  State<FikraNavBar> createState() => _FikraNavBarState();
}

class _FikraNavBarState extends State<FikraNavBar> with TickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 24);

  /// About one device pixel. Ends the underdamped spring promptly alongside the
  /// release fade rather than ticking at sub-pixel deltas.
  static const _tolerance = Tolerance(distance: .3, velocity: 6);
  late final _selection = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());
  late final _x = AnimationController.unbounded(vsync: this);
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  final _hover = ValueNotifier<int?>(null);
  Timer? _holdTimer;
  int? _pointer;
  double _pointerX = 0;
  OwnedHorizontalDragRecognizer? _drag;

  /// The drag recognizer holds the arena. It reports only the latest finger,
  /// so it gates switching while positions come from the tracked pointer.
  bool _dragging = false;
  int _selected = -1;
  bool _changed = false;
  double _width = 0;
  int _generation = 0;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  double get _tabWidth => (_width - 8) / widget.items.length;
  double _centre(int i) => 4 + (_rtl ? widget.items.length - 1 - i : i) * _tabWidth + _tabWidth / 2;
  double _clampX(double x) => x.clamp(4 + _tabWidth / 2, _width - 4 - _tabWidth / 2);
  int _hit(double x) {
    final physical = ((x - 4) / _tabWidth).floor().clamp(0, widget.items.length - 1);
    return _rtl ? widget.items.length - 1 - physical : physical;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.index;
    _pulse.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _x.stop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FikraMotion.reduced(context) && widget.index >= 0) _selection.value = widget.index.toDouble();
  }

  @override
  void didUpdateWidget(FikraNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An index this bar did not choose (deep link, Add, TalkBack) supersedes
    // the touch, so its release cannot reselect, and moves a settling lens.
    final external = widget.index != oldWidget.index && widget.index != _selected;
    _selected = widget.index;
    if (widget.index != oldWidget.index && widget.index >= 0) {
      if (FikraMotion.reduced(context) || oldWidget.index < 0) {
        _selection.value = widget.index.toDouble();
      } else {
        _selection.animateWith(
          SpringSimulation(
            FikraSprings.smooth,
            _selection.value,
            widget.index.toDouble(),
            _selection.velocity,
            tolerance: const Tolerance(distance: .001, velocity: .02),
            snapToEnd: true,
          ),
        );
      }
    }
    if (_pointer != null) {
      if (external || !widget.enabled || widget.index < 0) _finish();
    } else if (external && (_x.isAnimating || _pulse.isAnimating)) {
      _settle();
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _engageLens({required bool centerOnTab}) {
    if (_pointer == null) return;
    _cancelHold();
    final i = centerOnTab && _selected >= 0 ? _selected : _hit(_pointerX);
    _x.value = centerOnTab ? _centre(i) : _clampX(_pointerX);
    _hover.value = i;
    _pulse.value = 1;
  }

  void _choose(int index) {
    if (index == _selected) return;
    _selected = index;
    _changed = true;
    HapticFeedback.selectionClick();
    widget.onSelect(index, false);
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null || !widget.enabled) return;
    if (event.kind == PointerDeviceKind.mouse && (event.buttons & kPrimaryMouseButton) == 0) return;
    _generation++;
    _cancelHold();
    _pointer = event.pointer;
    _dragging = false;
    _changed = false;
    _x.stop();
    if (_pulse.value != 0 || _pulse.isAnimating) _pulse.reset();
    _pointerX = event.localPosition.dx;
    final i = _hit(_pointerX);
    _x.value = _centre(i);
    _choose(i);
    if (_pointer == null) return;
    final generation = _generation;
    _holdTimer = Timer(kLensHoldDelay, () {
      if (!mounted || _pointer == null || generation != _generation) return;
      _engageLens(centerOnTab: true);
    });
  }

  double _effectiveShrink(BuildContext context) =>
      FikraMotion.reduced(context) ? 0.0 : (widget.shrink?.value ?? 0.0).clamp(0.0, 1.0);

  double _barHeight(BuildContext context) =>
      ui.lerpDouble(72, FikraMotion.barShrunkHeight, _effectiveShrink(context))!.roundToDouble();

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final p = event.localPosition;
    if (p.dy < -60 || p.dy > _barHeight(context) + 60) {
      _finish();
      return;
    }
    _pointerX = p.dx;
    if (_pulse.value == 0) return;
    _x.value = _clampX(p.dx);
    final i = _hit(p.dx);
    _hover.value = i;
    if (_dragging) _choose(i);
  }

  void _activateDrag() {
    if (_pointer == null) return;
    _dragging = true;
    _engageLens(centerOnTab: false);
    _choose(_hit(_pointerX));
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    if (!_changed && _selected >= 0) widget.onSelect(_selected, true);
    _finish();
  }

  void _finish() {
    final pointer = _pointer;
    if (pointer == null) return;
    _cancelHold();
    _generation++;
    _pointer = null;
    _dragging = false;
    _hover.value = null;
    // Drop recognizer tracking/accepted state so a new finger while the old
    // one stays down must still cross its own horizontal slop or wait 200 ms.
    _drag?.rejectGesture(pointer);
    _settle();
  }

  void _settle() {
    if (_pulse.value == 0) {
      _x.stop();
      return;
    }
    final target = _selected < 0 ? _x.value : _centre(_selected);
    if (FikraMotion.reduced(context)) {
      _x.value = target;
    } else {
      _x.animateWith(SpringSimulation(_spring, _x.value, target, _x.velocity, tolerance: _tolerance, snapToEnd: true));
    }
    _pulse.reverse();
  }

  @override
  void dispose() {
    _cancelHold();
    _generation++;
    _drag = null;
    _hover.dispose();
    _selection.dispose();
    _x.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _width = box.maxWidth;
      final w = _tabWidth;
      final shrink = widget.shrink;
      return Listener(
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: (event) {
          if (event.pointer == _pointer) _finish();
        },
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            OwnedHorizontalDragRecognizer: GestureRecognizerFactoryWithHandlers<OwnedHorizontalDragRecognizer>(
              () => OwnedHorizontalDragRecognizer(
                (pointer) => widget.enabled && (_pointer == null || _pointer == pointer),
              ),
              (recognizer) {
                _drag = recognizer
                  ..dragStartBehavior = DragStartBehavior.down
                  ..onlyAcceptDragOnThreshold = true
                  ..onStart = ((_) => _activateDrag())
                  ..onEnd = ((_) => _dragging = false)
                  ..onCancel = (() => _dragging = false);
              },
            ),
          },
          child: AnimatedBuilder(
            animation: shrink ?? const AlwaysStoppedAnimation<double>(0),
            child: const Positioned.fill(
              child: Glass(padding: EdgeInsets.zero, child: SizedBox.expand()),
            ),
            builder: (context, glassBacking) => _buildBar(context, box.maxWidth, w, glassBacking!),
          ),
        ),
      );
    },
  );
}
