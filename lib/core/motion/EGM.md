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
    - Screen pop: `pop` (plain fade-out).
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
    back support. Button and programmatic pops use a plain fade-out lasting
    `FikraMotion.pop` (120 ms), exposed by `reverseTransitionDuration`.

## Invariants

- Give each state passed to `FikraSwitcher` a distinct `Key`. Without one, two
  states of the same widget type do not transition, because `AnimatedSwitcher`
  treats them as the same child.
- Toggling Reduce Motion never remounts `FikraSwitcher` content. A focused
  field would otherwise lose its IME state. Inside the `AnimatedSwitcher` the
  hierarchy is the same in both modes: keep the `ScaleTransition` in place under
  Reduce Motion, driven by a stopped animation at 1.0. With `animateSize`, the
  `AnimatedSwitcher` carries a `GlobalKey` owned by `_FikraSwitcherState`, so it
  moves in and out of the `AnimatedSize` wrapper without being rebuilt.
- The outgoing child of a `FikraSwitcher` stays visible but takes no pointer
  input, focus or semantics (`_ExitGuard`, active while the animation status is
  `reverse` or `dismissed`), so a replaced control cannot fire.
- The enter phase of `FikraSwitcher` runs after the exit phase: the forward
  duration is `exit + enter`, and `switchInCurve` is delayed by an `Interval`
  starting at `exit / (exit + enter)`. Exit is faster than enter.
- Under Reduce Motion, `FikraSwitcher` uses `FikraMotion.reducedFade` with no
  scale, and `animateSize` drops the `AnimatedSize` wrapper so the size changes
  at once. Never pass `Duration.zero` to an `AnimatedSize`: it jumps its
  controller to the end inside its own layout and re-dirties itself, which
  fails a debug assertion ("mutated in its own performLayout").
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
- Pushes keep the 400 ms `FikraMotion.push` timeline, 100 ms
  `FikraMotion.pushFade` fade and 30 dp `FikraMotion.pushOffset` slide.
- Button and programmatic pops have no slide and fade linearly over the
  120 ms `FikraMotion.pop` reverse timeline, also under Reduce Motion.
- Under Reduce Motion, page entrances fade in over
  `FikraMotion.reducedFade` (180 ms) on the `FikraMotion.push` timeline,
  with no translation or scale. Predictive back scrubs this same fade.
- Predictive back scrubs the route's own timeline. `_PredictiveBack` ignores
  button events, routes that are not current, and routes with
  `popGestureEnabled` false.
- On predictive back commit, `_visualAnimation` is re-parented to map the
  restarted reverse controller onto the current gesture value. Removing this
  causes a visual jump. This value mapping is duration-independent: the
  restarted controller runs from 1 to 0 over `FikraMotion.pop`, while the
  visual runs from the gesture value to 0. Flutter keeps
  `userGestureInProgress` true through commit and cancel settling; these keep
  the gesture visuals instead of switching to the button-pop fade.
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
  guard, `animateSize` swaps under Reduce Motion without a layout assertion,
  content and focus kept across a Reduce Motion toggle, push direction and
  duration, plain pop fades and route removal within the pop budget (including
  Reduce Motion), and predictive back progress, cancellation and continuous
  commit at multiple gesture positions.

## Motion & delight (redesign phase 7)

- `motion.dart`: adds tokens `saveTick` (360 ms), `pulse` (1600 ms), `pulseCurve`, `pulseExpand` (6 dp), `waveformStep` (90 ms), `staggerStep` (32 ms), `staggerItem` (160 ms), `staggerTotal` (384 ms), `staggerMaxItems` (8), `staggerOffset` (10 dp), `roll` (220 ms), `rollCurve`, `containerPop` (280 ms), `containerFadeStart` (0.12), `containerFadeEnd` (0.55), `barShrinkDistance` (120 dp) and `barShrunkHeight` (52 dp).
- `page_transitions.dart`: exports `FikraPredictiveBack`, shared by `FikraPageTransitionsBuilder` and `ContainerTransformPage`.
- `container_transform.dart`: `CardOrigin` (`initialRect`, `borderRadius`, `currentRect`, `fromContext`) and `ContainerTransformPage<T>` (key `note-container-transform`). Keeps one stable wrapper tree around the page across open, rest, predictive back, non-flying pop and Reduce Motion so the page never reparents or remounts its `State`. Grows from the tapped card's global rect with `colorScheme.surface` cross-fading to `scaffoldBackgroundColor` and full screen; reverses into the live card rect when still mounted, `TickerMode`-enabled and overlapping its scroll viewport, falling back to `FikraMotion.pop` otherwise and to `FikraPageTransitionsBuilder` motion under Reduce Motion.
- `stagger.dart`: `StaggerController` + `StaggeredEntry`. Records each project once its data loads (even if empty, so later stream arrivals never stagger) and animates only on a visible first load or a visible project switch (`onProjectChanged`); switching projects while hidden marks the project shown so returning to the tab never staggers. `StaggeredEntry` keeps one consistent `AnimatedBuilder` element depth at rest and in flight.
- `rolling_text.dart`: `RollingText` + `@visibleForTesting` `RollingDigit`. Renders a single `Text` (including optional `textAlign`) on first build, at rest and under Reduce Motion; vertically rolls only changed digits (Western `0-9` and Arabic-Indic `٠-٩`) in LTR digit order while preserving `maxLines`/`overflow` on prefix and suffix and exposing the final value via `Semantics`.
- `recording_pulse.dart`: `RecordingPulse`. Isolated in `RepaintBoundary` + `CustomPaint`; stops its ticker when inactive, hidden via `TickerMode`, or under Reduce Motion (draws a static ring).

## Branch and note-open performance (P0.1)

- Container transforms morph only the surface, rectangle and clip. Incoming page content keeps its final layout and scale 1 throughout push, rest and pop; the existing opacity interval, live-card reverse lookup and Reduce Motion fallback remain. `container_transform_source.dart` supplies `ContainerTransformSource`, a RenderOpacity wrapper captured by CardOrigin that fades the source card oppositely without widget builds. Route disposal restores source opacity, including interrupted pushes; Reduce Motion leaves it unchanged.
- `stagger_visibility.dart`: `StaggerVisibility` is a zero-size leaf owning TickerMode/Reduce Motion dependencies. It stops hidden staggers and optionally clears hidden selection after the frame, without rebuilding a screen or notifying sibling rows during build.
- `test/container_transform_test.dart` checks Arabic text ancestors, final page size, interpolated clip/radius and fade in both directions, plus the unchanged reduced-motion fallback. `test/branch_build_test.dart` checks screen build counts and hidden/reduced stagger shutdown.
