import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/glass_lens.dart';
import 'tab_label.dart';

/// Pointer tracking is confined to this box. Only the lens listens to its
/// pixel-position controller; branch navigators never listen to pointer moves.
class FikraNavBar extends StatefulWidget {
  const FikraNavBar({super.key, required this.items, required this.index, required this.onSelect, this.enabled = true});
  final List<(String, IconData)> items;

  /// Visible tab index; -1 while Add is current.
  final int index;
  final bool enabled;
  final void Function(int index, bool reselect) onSelect;

  @override
  State<FikraNavBar> createState() => _FikraNavBarState();
}

class _FikraNavBarState extends State<FikraNavBar> with TickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 24);

  /// About one device pixel. The default 0.001 px tolerance keeps this
  /// underdamped spring (decay 12/s) ticking, and the lens's backdrop pass
  /// alive, for ~1.2 s after release; this ends it at ~0.45 s.
  static const _tolerance = Tolerance(distance: .3, velocity: 6);
  late final _x = AnimationController.unbounded(vsync: this);
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  final _hover = ValueNotifier<int?>(null);
  int? _pointer;
  double _pointerX = 0;

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
  int _hit(double x) {
    final physical = ((x - 5) / _tabWidth).floor().clamp(0, widget.items.length - 1);
    return _rtl ? widget.items.length - 1 - physical : physical;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.index;
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
    } else if (external && _x.isAnimating) {
      _settle();
    }
  }

  void _choose(int index) {
    if (index == _selected) return;
    _selected = index;
    _changed = true;
    HapticFeedback.selectionClick();
    widget.onSelect(index, false);
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _generation++;
    _pointer = event.pointer;
    _changed = false;
    _x.stop();
    _pulse.stop();
    _pointerX = event.localPosition.dx;
    final i = _hit(_pointerX);
    _x.value = _centre(i);
    _hover.value = i;
    _pulse.value = 1; // visible on the very first frame after pointer-down
    _choose(i);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final p = event.localPosition;
    if (p.dy < -60 || p.dy > 72 + 60) {
      _finish();
      return;
    }
    _pointerX = p.dx;
    _x.value = p.dx.clamp(5 + _tabWidth / 2, _width - 5 - _tabWidth / 2);
    final i = _hit(p.dx);
    _hover.value = i;
    if (_dragging) _choose(i);
  }

  void _dragStart(DragStartDetails _) {
    _dragging = true;
    if (_pointer != null) _choose(_hit(_pointerX));
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    if (!_changed && _selected >= 0) widget.onSelect(_selected, true);
    _finish();
  }

  void _finish() {
    if (_pointer == null) return;
    _pointer = null;
    _hover.value = null;
    _settle();
  }

  void _settle() {
    final generation = ++_generation;
    final target = _selected < 0 ? _x.value : _centre(_selected);
    if (FikraMotion.reduced(context)) {
      _x.value = target;
      _pulse.reverse();
    } else {
      _x
          .animateWith(SpringSimulation(_spring, _x.value, target, _x.velocity, tolerance: _tolerance, snapToEnd: true))
          .whenCompleteOrCancel(() {
            if (mounted && generation == _generation) _pulse.reverse();
          });
    }
  }

  @override
  void dispose() {
    _generation++;
    _hover.dispose();
    _x.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _width = box.maxWidth;
      final w = _tabWidth;
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
            HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
              HorizontalDragGestureRecognizer.new,
              (recognizer) => recognizer
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = _dragStart
                ..onEnd = ((_) => _dragging = false)
                ..onCancel = (() => _dragging = false),
            ),
          },
          child: SizedBox(
            key: const ValueKey('floating-tab-bar'),
            // Fill the offered width. The Stack's only unpositioned child is
            // the hidden lens, so it would otherwise shrink to 0 dp and drop taps.
            width: box.maxWidth,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: Glass(padding: EdgeInsets.zero, child: SizedBox.expand()),
                ),
                if (widget.index >= 0)
                  Positioned(
                    left: _centre(widget.index) - w / 2,
                    top: 5,
                    width: w,
                    height: 62,
                    child: FadeTransition(
                      opacity: _pulse.drive(Tween(begin: 1.0, end: .32)),
                      child: DecoratedBox(
                        key: const ValueKey('nav-selected-pill'),
                        decoration: BoxDecoration(
                          color: context.colors.selected,
                          borderRadius: BorderRadius.circular(32),
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
                          height: 88,
                          child: Transform.translate(
                            offset: Offset(_x.value.clamp(5 + w / 2, _width - 5 - w / 2) - (w + 20) / 2, 0),
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
          ),
        ),
      );
    },
  );
}
