# Motion

## Overview

Motion vocabulary for FIKRA's Plasma One design: duration, curve and spring
tokens, the content-swap widget, the press-feedback widget, and the page
transition registered on the app theme. Every primitive here honors Reduce
Motion (`MediaQuery.disableAnimations`).

The package imports only Flutter. It must not depend on `../theme/`; the
dependency runs the other way (`theme/fikra_theme.dart` registers
`FikraPageTransitionsBuilder`).

## Interface

- `motion.dart`
  - `FikraMotion` (`abstract final`): transition tokens.
    - Enter: `enter`, `enterScale`, `enterCurve`.
    - Exit: `exit`, `exitCurve`.
    - Expansion: `expand`, `expandCurve`.
    - Screen push: `push`, `pushFade`, `pushOffset`, `pushCurve`.
    - Bottom sheet: `sheet`, `sheetCurve`.
    - Chat: `messageOffset` (dp).
    - Reduce Motion: `reducedFade`.
    - `static bool reduced(BuildContext context)`: true when animations are
      disabled; false when no `MediaQuery` is present.
  - `FikraSwitcher({required Widget child, bool animateSize = false, AlignmentGeometry alignment = Alignment.topCenter})`:
    content swap in which the old child fades out, then the new child fades and
    scales in. `animateSize` also eases the height change.
- `pressable.dart`
  - `FikraSprings` (`abstract final`): `smooth`, `snappy`, `stiff`
    (`SpringDescription`, all with damping ratio 0.75).
  - `Pressable({required Widget child, VoidCallback? onTap, VoidCallback? onLongPress, double pressedScale = 0.964, String? semanticLabel, bool? selected, bool minTarget = false})`:
    spring-scale press feedback with no ripple.
  - `Pressable.minTargetSize`: 48.0 dp.
- `page_transitions.dart`
  - `FikraPageTransitionsBuilder` (`PageTransitionsBuilder`): a short slide from
    the logical end plus a fade, lasting `FikraMotion.push`, with predictive
    back support.

## Invariants

- Give each state passed to `FikraSwitcher` a distinct `Key`. Without one, two
  states of the same widget type do not transition, because `AnimatedSwitcher`
  treats them as the same child.
- `FikraSwitcher` builds the same widget hierarchy with and without Reduce
  Motion, so toggling it never remounts content. A focused field would otherwise
  lose its IME state. Keep the `ScaleTransition` in place under Reduce Motion,
  driven by a stopped animation at 1.0.
- The outgoing child of a `FikraSwitcher` stays visible but takes no pointer
  input, focus or semantics (`_ExitGuard`, active while the animation status is
  `reverse` or `dismissed`), so a replaced control cannot fire.
- The enter phase of `FikraSwitcher` runs after the exit phase: the forward
  duration is `exit + enter`, and `switchInCurve` is delayed by an `Interval`
  starting at `exit / (exit + enter)`. Exit is faster than enter.
- Under Reduce Motion, `FikraSwitcher` uses `FikraMotion.reducedFade` with no
  scale, and `animateSize` resolves to `Duration.zero`.
- `Pressable` is enabled when `onTap` or `onLongPress` is set. Under Reduce
  Motion its scale stays at 1.
- `Pressable.semanticLabel` replaces the child's semantics. A labelled
  `Pressable` must keep exposing its own `onTap` and `onLongPress` semantics
  actions, because excluding child semantics also drops the `GestureDetector`'s
  actions.
- A `Pressable` with a label or a handler is a semantic button. One with neither
  is plain content (for example a read-only chip).
- `Pressable.minTarget` grows the hit area to 48 x 48 dp around a smaller visual
  without changing the visual size.
- `FikraPageTransitionsBuilder` leaves the covered route still
  (`secondaryAnimation` is unused) and flips its slide direction in RTL so the
  page always enters from the logical end.
- Under Reduce Motion, page transitions are a fade finishing after
  `FikraMotion.reducedFade` on the `FikraMotion.push` timeline, with no
  translation or scale. Predictive back uses the same fade.
- Predictive back scrubs the route's own timeline. `_PredictiveBack` ignores
  button events, routes that are not current, and routes with
  `popGestureEnabled` false.
- On predictive back commit, `_visualAnimation` is re-parented to map the
  restarted reverse controller onto the current gesture value. Removing this
  causes a visual jump.
- The builder only runs on routes that consult the theme's page transitions. See
  `_pushed` in `lib/app/router.dart`, which builds a `MaterialPage` explicitly
  because go_router falls back to `NoTransitionPage` for `builder:` routes.

## Side Effects

- `_PredictiveBackState` registers a `WidgetsBindingObserver` in `initState` and
  removes it in `dispose`. While a gesture is active it drives the route through
  `handleStartBackGesture`, `handleUpdateBackGestureProgress`,
  `handleCancelBackGesture` and `handleCommitBackGesture`.
- `_PressableState` owns an unbounded `AnimationController`, which holds a ticker
  until `dispose`.
- `FikraMotion` and `FikraSprings` are constants with no side effects.

## Verification

- Run: `flutter analyze && flutter test`
- `test/motion_test.dart` covers `Pressable` semantics, the `FikraSwitcher` exit
  guard, push direction, reduced page fades, and predictive back cancel and
  commit.
