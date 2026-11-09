import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

/// A short logical-end slide, in dp rather than a fraction of screen width.
/// Button pops fade out without sliding. The covered route stays still.
/// Predictive back scrubs the entrance timeline, including its slide.
class FikraPageTransitionsBuilder extends PageTransitionsBuilder {
  const FikraPageTransitionsBuilder();

  @override
  Duration get transitionDuration => FikraMotion.push;

  @override
  Duration get reverseTransitionDuration => FikraMotion.pop;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = FikraMotion.reduced(context);
    final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return _PredictiveBack(
      route: route,
      animation: animation,
      builder: (context, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final progress = animation.value.clamp(0.0, 1.0);
          // Flutter keeps userGestureInProgress true through predictive commit
          // and cancel settling, so neither switches to the button-pop visuals.
          final buttonPop =
              animation.status == AnimationStatus.reverse && !(route.navigator?.userGestureInProgress ?? false);
          final fade = Interval(
            0,
            (reduced ? FikraMotion.reducedFade : FikraMotion.pushFade).inMilliseconds / FikraMotion.push.inMilliseconds,
          );
          return Transform.translate(
            offset: reduced || buttonPop
                ? Offset.zero
                : Offset(direction * FikraMotion.pushOffset * (1 - FikraMotion.pushCurve.transform(progress)), 0),
            child: Opacity(opacity: buttonPop ? progress : fade.transform(progress), child: child),
          );
        },
      ),
    );
  }
}

/// Uses the same public route gesture hooks as Flutter's predictive builder,
/// while retaining FIKRA's transition instead of the native scale/parallax.
class _PredictiveBack extends StatefulWidget {
  const _PredictiveBack({required this.route, required this.animation, required this.builder});
  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Widget Function(BuildContext context, Animation<double> animation) builder;

  @override
  State<_PredictiveBack> createState() => _PredictiveBackState();
}

class _PredictiveBackState extends State<_PredictiveBack> with WidgetsBindingObserver {
  late final ProxyAnimation _visualAnimation = ProxyAnimation(widget.animation);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !widget.route.isCurrent || !widget.route.popGestureEnabled) return false;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
  }

  @override
  void handleCancelBackGesture() => widget.route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() {
    // Flutter restarts the route's reverse controller at 1 on commit. Map that
    // remaining timeline onto the current gesture value to avoid a visual jump.
    // This value remapping is duration-independent: the controller now runs
    // 1 → 0 over FikraMotion.pop, while the visual runs gestureValue → 0.
    _visualAnimation.parent = widget.animation.drive(Tween(begin: 0.0, end: widget.animation.value));
    widget.route.handleCommitBackGesture();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visualAnimation.parent = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _visualAnimation);
}
