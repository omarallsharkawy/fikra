import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Coordinates a one-shot stagger entrance for at most [FikraMotion.staggerMaxItems]
/// cards when a project's list first becomes visible. Never runs on scroll,
/// stream updates, tab returns, hidden tabs or under Reduce Motion.
class StaggerController {
  StaggerController(TickerProvider vsync)
    : _controller = AnimationController(vsync: vsync, duration: FikraMotion.staggerTotal, value: 1);

  final AnimationController _controller;
  String? _projectId;
  Map<String, int> _slots = const {};

  String? get projectId => _projectId;
  bool get isAnimating => _controller.isAnimating;
  Animation<double> get animation => _controller;

  /// Records [projectId] once its data has loaded, and starts the stagger only
  /// when [tickerEnabled] is true, Reduce Motion is off, and the initial list is non-empty.
  void maybeStart({
    required String? projectId,
    required Iterable<String> visibleIds,
    required bool tickerEnabled,
    required bool reduced,
  }) {
    if (projectId == null || _projectId == projectId) return;
    _projectId = projectId;
    final first = visibleIds.take(FikraMotion.staggerMaxItems).toList();
    if (!tickerEnabled || reduced || first.isEmpty) {
      stop();
      return;
    }
    _slots = {for (final (i, id) in first.indexed) id: i};
    _controller.value = 0;
    _controller.forward().whenCompleteOrCancel(() {
      if (_controller.value >= 1) _slots = const {};
    });
  }

  /// Stops any in-flight stagger immediately if the tab hides or Reduce Motion turns on.
  void syncVisibility({required bool tickerEnabled, required bool reduced}) {
    if ((!tickerEnabled || reduced) && (_controller.isAnimating || _slots.isNotEmpty)) {
      stop();
    }
  }

  /// Handles a project switch: resets so a visible switch staggers, or marks
  /// [nextProjectId] as already shown when hidden so returning to the tab does not stagger.
  void onProjectChanged(String? nextProjectId, {required bool tickerEnabled}) {
    stop();
    _projectId = tickerEnabled ? null : nextProjectId;
  }

  void reset() {
    _projectId = null;
    stop();
  }

  void stop() {
    _controller.stop();
    _controller.value = 1;
    _slots = const {};
  }

  int? slotOf(String id) => _slots[id];

  void dispose() {
    _slots = const {};
    _controller.dispose();
  }
}

/// Animates [child] with a staggered fade and slight upward rise if [itemId] is
/// in [stagger]'s initial visible batch; otherwise returns [child] untouched.
class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({super.key, required this.stagger, required this.itemId, required this.child});

  final StaggerController stagger;
  final String itemId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Keep one consistent element depth whether staggering or at rest so cards
    // never remount (preserving Pressable state and CardOrigin element identity).
    return AnimatedBuilder(
      animation: stagger.animation,
      child: child,
      builder: (context, child) {
        final slot = stagger.slotOf(itemId);
        if (slot == null || stagger.animation.value >= 1 || FikraMotion.reduced(context)) {
          return child!;
        }
        final totalMs = FikraMotion.staggerTotal.inMilliseconds;
        final start = (slot * FikraMotion.staggerStep.inMilliseconds) / totalMs;
        final end =
            ((slot * FikraMotion.staggerStep.inMilliseconds) + FikraMotion.staggerItem.inMilliseconds) / totalMs;
        final p = Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: FikraMotion.enterCurve,
        ).transform(stagger.animation.value);
        return Transform.translate(
          offset: Offset(0, FikraMotion.staggerOffset * (1 - p)),
          child: Opacity(opacity: p, child: child),
        );
      },
    );
  }
}
