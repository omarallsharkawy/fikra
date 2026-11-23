import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderOpacity;

import 'motion.dart';
import 'page_transitions.dart';

part 'container_transform_source.dart';

/// Origin rectangle and live on-screen lookup for a tapped card opening a page.
class CardOrigin {
  const CardOrigin({required this.initialRect, required this.borderRadius, this.currentRect}) : _element = null;

  const CardOrigin._({
    required this.initialRect,
    required this.borderRadius,
    required this.currentRect,
    required WeakReference<Element> this._element,
  });

  /// Global rectangle of the source card when tapped.
  final Rect initialRect;
  final double borderRadius;

  /// Returns the card's current global rectangle if it is still mounted,
  /// onstage and visible in its viewport; null when scrolled away, hidden or removed.
  final Rect? Function()? currentRect;
  final WeakReference<Element>? _element;

  static CardOrigin? fromContext(BuildContext context, {double borderRadius = 24}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final initial = box.localToGlobal(Offset.zero) & box.size;
    final ref = WeakReference(context as Element);
    return CardOrigin._(
      initialRect: initial,
      borderRadius: borderRadius,
      element: ref,
      currentRect: () => _liveGlobalRect(ref.target, checkTickerMode: true),
    );
  }

  Rect? _rectBeforeOverlayRebuild() =>
      _element != null ? _liveGlobalRect(_element.target, checkTickerMode: false) : currentRect?.call();

  void _fadeSource(double opacity) {
    final element = _element?.target;
    if (element == null || !element.mounted) return;
    final box = element.renderObject;
    if (box is _CardSource) box.opacity = opacity;
  }

  static Rect? _liveGlobalRect(Element? element, {required bool checkTickerMode}) {
    if (element == null || !element.mounted) return null;
    if (checkTickerMode && !TickerMode.valuesOf(element).enabled) return null;
    final box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final probe = rect.width > 4 && rect.height > 4 ? rect.deflate(2) : rect;
    final scrollable = Scrollable.maybeOf(element);
    if (scrollable != null) {
      final scrollBox = scrollable.context.findRenderObject();
      if (scrollBox is RenderBox && scrollBox.attached && scrollBox.hasSize) {
        final viewport = scrollBox.localToGlobal(Offset.zero) & scrollBox.size;
        if (!viewport.overlaps(probe)) return null;
      }
    }
    final viewSize = MediaQuery.maybeSizeOf(element);
    if (viewSize != null && !(Offset.zero & viewSize).overlaps(probe)) return null;
    return rect;
  }
}

/// Page that grows from [origin] with the card's surface color and cross-fades
/// to [child]. Reverses into the card when still on screen; falls back to the
/// normal pop otherwise, and to [FikraPageTransitionsBuilder] motion under Reduce Motion.
class ContainerTransformPage<T> extends Page<T> {
  const ContainerTransformPage({
    required this.child,
    required this.origin,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final CardOrigin origin;

  @override
  Route<T> createRoute(BuildContext context) => _ContainerTransformRoute<T>(this);
}

class _ContainerTransformRoute<T> extends PageRoute<T> {
  _ContainerTransformRoute(ContainerTransformPage<T> page) : super(settings: page);

  ContainerTransformPage<T> get _page => settings as ContainerTransformPage<T>;
  Rect? _activeOriginGlobal;
  bool _reverseFlies = true;
  bool _reversePrepared = false;

  @override
  bool get maintainState => true;

  @override
  void dispose() {
    _page.origin._fadeSource(1);
    super.dispose();
  }

  @override
  Duration get transitionDuration => FikraMotion.push;

  @override
  Duration get reverseTransitionDuration => FikraMotion.containerPop;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  TickerFuture didPush() {
    _activeOriginGlobal = _page.origin.initialRect;
    _reverseFlies = true;
    _reversePrepared = false;
    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    final reduced = navigator != null && FikraMotion.reduced(navigator!.context);
    final preRect = reduced ? null : _page.origin._rectBeforeOverlayRebuild();
    _reverseFlies = preRect != null;
    _reversePrepared = preRect == null;
    if (preRect != null) _activeOriginGlobal = preRect;
    controller?.reverseDuration = _reverseFlies ? FikraMotion.containerPop : FikraMotion.pop;
    return super.didPop(result);
  }

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    _reversePrepared = false;
    if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = false;
    super.handleStartBackGesture(progress: progress);
  }

  @override
  void handleCancelBackGesture() {
    super.handleCancelBackGesture();
    if ((animation?.isCompleted ?? false) && overlayEntries.isNotEmpty) {
      overlayEntries.first.opaque = opaque;
    }
  }

  @override
  void handleCommitBackGesture() {
    controller?.reverseDuration = _reverseFlies ? FikraMotion.containerPop : FikraMotion.pop;
    super.handleCommitBackGesture();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(scopesRoute: true, explicitChildNodes: true, child: RepaintBoundary(child: _page.child));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = FikraMotion.reduced(context);
    final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return FikraPredictiveBack(
      route: this,
      animation: animation,
      builder: (context, visualAnimation) => AnimatedBuilder(
        animation: visualAnimation,
        child: child,
        builder: (context, pageChild) {
          final raw = visualAnimation.value.clamp(0.0, 1.0);
          final reversing = animation.status == AnimationStatus.reverse;
          final gesture = navigator?.userGestureInProgress ?? false;
          if ((reversing || gesture) && raw < 0.999) {
            if (!_reversePrepared) {
              _reversePrepared = true;
              final live = reduced ? null : _page.origin.currentRect?.call();
              _reverseFlies = live != null;
              if (live != null) _activeOriginGlobal = live;
            }
          } else if (!reversing && !gesture && _reversePrepared) {
            _reversePrepared = false;
          }

          final navBox = navigator?.context.findRenderObject();
          final fullSize = navBox is RenderBox && navBox.hasSize ? navBox.size : MediaQuery.sizeOf(context);
          final fullRect = Offset.zero & fullSize;
          final flying = !reduced && raw < 0.999 && (!(reversing || gesture) || _reverseFlies);
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          var rect = fullRect;
          var radius = 0.0;
          var scrimColor = Colors.transparent;
          var containerColor = Colors.transparent;
          var slideOffset = Offset.zero;
          var pageOpacity = 1.0;
          var borderAlpha = 0.0;

          if (flying) {
            final globalOrigin = _activeOriginGlobal ?? _page.origin.initialRect;
            final startRect = navBox is RenderBox && navBox.attached
                ? (navBox.globalToLocal(globalOrigin.topLeft) & globalOrigin.size)
                : globalOrigin;
            final t = gesture
                ? Curves.easeOutCubic.transform(raw)
                : reversing
                ? 1 - FikraMotion.pushCurve.transform(1 - raw)
                : FikraMotion.pushCurve.transform(raw);
            rect = Rect.lerp(startRect, fullRect, t)!;
            radius = ui.lerpDouble(_page.origin.borderRadius, 0, t)!;
            const crossFade = Interval(
              FikraMotion.containerFadeStart,
              FikraMotion.containerFadeEnd,
              curve: Curves.easeOut,
            );
            pageOpacity = crossFade.transform(t);
            containerColor = Color.lerp(scheme.surface, theme.scaffoldBackgroundColor, pageOpacity)!;
            scrimColor = scheme.scrim.withValues(alpha: scheme.scrim.a * 0.55 * t);
            borderAlpha = t < 0.98 ? (1 - t).clamp(0.0, 1.0) : 0.0;
          } else if (raw < 0.999) {
            final buttonPop = reversing && !gesture;
            final fade = Interval(
              0,
              (reduced ? FikraMotion.reducedFade : FikraMotion.pushFade).inMilliseconds /
                  FikraMotion.push.inMilliseconds,
            );
            slideOffset = reduced || buttonPop
                ? Offset.zero
                : Offset(direction * FikraMotion.pushOffset * (1 - FikraMotion.pushCurve.transform(raw)), 0);
            pageOpacity = buttonPop ? raw : fade.transform(raw);
          }

          final borderRadius = BorderRadius.circular(radius);
          _page.origin._fadeSource(flying ? 1 - pageOpacity : 1);
          // Keep one stable ancestor tree around pageChild across open, rest,
          // predictive back, non-flying pop and Reduce Motion so the page never
          // reparents or remounts its State.
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                key: const ValueKey('ct-scrim'),
                child: ColoredBox(color: scrimColor),
              ),
              Positioned.fromRect(
                key: const ValueKey('ct-body'),
                rect: rect,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: containerColor, borderRadius: borderRadius),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    clipBehavior: flying ? Clip.antiAlias : Clip.none,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minWidth: fullSize.width,
                      maxWidth: fullSize.width,
                      minHeight: fullSize.height,
                      maxHeight: fullSize.height,
                      child: Transform.translate(
                        offset: slideOffset,
                        child: Opacity(opacity: pageOpacity, child: pageChild),
                      ),
                    ),
                  ),
                ),
              ),
              if (flying)
                Positioned.fromRect(
                  key: const ValueKey('note-container-transform'),
                  rect: rect,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        border: borderAlpha > 0
                            ? Border.all(color: scheme.outline.withValues(alpha: borderAlpha), width: 0.6)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
