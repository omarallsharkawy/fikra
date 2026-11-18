import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_lens.dart';
import 'tab_label.dart';

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
  late final _x = AnimationController.unbounded(vsync: this);
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  final _hover = ValueNotifier<int?>(null);
  Timer? _holdTimer;
  int? _pointer;
  double _pointerX = 0;
  _OwnedHorizontalDragRecognizer? _drag;

  /// The drag recognizer holds the arena. It reports only the latest finger,
  /// so it gates switching while positions come from the tracked pointer.
  bool _dragging = false;
  int _selected = -1;
  bool _changed = false;
  double _width = 0;
  int _generation = 0;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  double get _tabWidth => (_width - 10) / widget.items.length;
  double _centre(int i) => 5 + (_rtl ? widget.items.length - 1 - i : i) * _tabWidth + _tabWidth / 2;
  double _clampX(double x) => x.clamp(5 + _tabWidth / 2, _width - 5 - _tabWidth / 2);
  int _hit(double x) {
    final physical = ((x - 5) / _tabWidth).floor().clamp(0, widget.items.length - 1);
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
  void didUpdateWidget(FikraNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An index this bar did not choose (deep link, Add, TalkBack) supersedes
    // the touch, so its release cannot reselect, and moves a settling lens.
    final external = widget.index != oldWidget.index && widget.index != _selected;
    _selected = widget.index;
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
    _x.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _buildBar(BuildContext context, double maxWidth, double w, Widget glassBacking) {
    final s = _effectiveShrink(context);
    // Quantize height to whole dp so Glass only relays out across 20 discrete
    // steps instead of every sub-pixel scroll frame, and reuse glassBacking.
    final barHeight = ui.lerpDouble(72, FikraMotion.barShrunkHeight, s)!.roundToDouble();
    final pillHeight = barHeight - 10;
    final lensHeight = barHeight + 16;
    return SizedBox(
      key: const ValueKey('floating-tab-bar'),
      // Fill the offered width. The Stack's only unpositioned child is
      // the hidden lens, so it would otherwise shrink to 0 dp and drop taps.
      width: maxWidth,
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          glassBacking,
          if (widget.index >= 0)
            Positioned(
              left: _centre(widget.index) - w / 2,
              top: 5,
              width: w,
              height: pillHeight,
              child: FadeTransition(
                opacity: _pulse.drive(Tween(begin: 1.0, end: .32)),
                child: DecoratedBox(
                  key: const ValueKey('nav-selected-pill'),
                  decoration: BoxDecoration(
                    color: context.colors.selected,
                    borderRadius: BorderRadius.circular(pillHeight / 2),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: Listenable.merge([_x, _pulse]),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => GlassLens(opacity: _pulse.value, child: const SizedBox.expand()),
            ),
            builder: (context, lens) => _pulse.value == 0
                ? const SizedBox.shrink()
                : Positioned(
                    left: 0,
                    top: -8,
                    width: w + 20,
                    height: lensHeight,
                    child: Transform.translate(
                      offset: Offset(_clampX(_x.value) - (w + 20) / 2, 0),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: SizedBox(key: const ValueKey('nav-lens'), child: lens),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: RepaintBoundary(
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: TabLabel(
                          key: ValueKey('nav-$i'),
                          label: widget.items[i].$1,
                          icon: widget.items[i].$2,
                          selected: widget.index == i,
                          index: i,
                          hover: _hover,
                          shrink: s,
                          onActivate: () => widget.onSelect(i, i == widget.index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            _OwnedHorizontalDragRecognizer: GestureRecognizerFactoryWithHandlers<_OwnedHorizontalDragRecognizer>(
              () => _OwnedHorizontalDragRecognizer(
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

class _OwnedHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  _OwnedHorizontalDragRecognizer(this.ownsPointer);
  final bool Function(int pointer) ownsPointer;

  @override
  void addPointer(PointerDownEvent event) {
    if (ownsPointer(event.pointer)) super.addPointer(event);
  }
}
