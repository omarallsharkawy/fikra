import 'package:flutter/widgets.dart';

/// Motion tokens (Plasma One, measured on device where noted). Interactive
/// motion uses the springs in pressable.dart; these are for transitions.
abstract final class FikraMotion {
  /// Mount / content enter: opacity 0 → 1 and scale 0.96 → 1.
  static const enter = Duration(milliseconds: 250);
  static const enterScale = 0.96;
  static const enterCurve = Curves.easeOutCubic;

  /// Small upward entrance for newly appended chat messages, in dp.
  static const messageOffset = 8.0;

  /// Exit is faster than enter. A content swap waits for the exit first.
  static const exit = Duration(milliseconds: 120);
  static const exitCurve = Curves.easeInCubic;

  /// Expansions (height / size changes).
  static const expand = Duration(milliseconds: 280);
  static const expandCurve = Curves.easeOutCubic;

  /// Screen push (measured): ~100 ms cross-fade plus a ~30 dp slide from the
  /// end side that decelerates over ~400 ms. Pop mirrors it.
  static const push = Duration(milliseconds: 400);
  static const pushFade = Duration(milliseconds: 100);
  static const pushOffset = 30.0;
  static const pushCurve = Cubic(0.23, 1, 0.32, 1);

  /// Bottom sheet (measured): ease-in-out ~310 ms, ~30 % scrim.
  static const sheet = Duration(milliseconds: 310);
  static const sheetCurve = Cubic(0.42, 0, 0.58, 1);

  /// Reduce Motion: plain fades only.
  static const reducedFade = Duration(milliseconds: 180);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Content swap: the old child fades out (120 ms), then the new one fades and
/// scales in (0.96 → 1, 250 ms). Give each state a distinct [Key].
/// With [animateSize] the height change between states is eased too.
class FikraSwitcher extends StatelessWidget {
  const FikraSwitcher({super.key, required this.child, this.animateSize = false, this.alignment = Alignment.topCenter});

  final Widget child;
  final bool animateSize;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduced = FikraMotion.reduced(context);
    final exitMs = FikraMotion.exit.inMilliseconds;
    final total = exitMs + FikraMotion.enter.inMilliseconds;
    Widget switcher = AnimatedSwitcher(
      duration: reduced ? FikraMotion.reducedFade : Duration(milliseconds: total),
      reverseDuration: reduced ? FikraMotion.reducedFade : FikraMotion.exit,
      switchInCurve: reduced ? Curves.linear : Interval(exitMs / total, 1, curve: FikraMotion.enterCurve),
      switchOutCurve: reduced ? Curves.linear : FikraMotion.exitCurve,
      layoutBuilder: (current, previous) => Stack(alignment: alignment, children: [...previous, ?current]),
      // One hierarchy for both modes, so toggling Reduce Motion never remounts
      // the content (a focused field would lose its IME state).
      transitionBuilder: (child, animation) => _ExitGuard(
        animation: animation,
        child: ScaleTransition(
          scale: reduced
              ? const AlwaysStoppedAnimation(1.0)
              : Tween(begin: FikraMotion.enterScale, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: child,
    );
    if (animateSize) {
      switcher = AnimatedSize(
        duration: reduced ? Duration.zero : FikraMotion.expand,
        curve: FikraMotion.expandCurve,
        alignment: alignment,
        child: switcher,
      );
    }
    return switcher;
  }
}

/// The outgoing child of a switch stays visible during its exit but takes no
/// taps, focus or semantics, so a control can't fire after it was replaced.
class _ExitGuard extends AnimatedWidget {
  const _ExitGuard({required Animation<double> animation, required this.child}) : super(listenable: animation);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final status = (listenable as Animation<double>).status;
    final exiting = status == AnimationStatus.reverse || status == AnimationStatus.dismissed;
    return IgnorePointer(
      ignoring: exiting,
      child: ExcludeFocus(
        excluding: exiting,
        child: ExcludeSemantics(excluding: exiting, child: child),
      ),
    );
  }
}
