# Widgets

## Overview

Shared UI kit for FIKRA screens: opaque reading surfaces, tiered floating glass, buttons, fields, chips, badges,
banners, empty and error states, the segmented control, sheet and dialog
helpers, toasts, the async body wrapper, and the local audio player. It is built
on [theme](../theme/EGM.md) tokens and [motion](../motion/EGM.md) primitives.
User-facing default strings resolve from `context.l10n`, in
`status_badges.dart` (`FikraBadge`), `empty_states.dart` (`LoadErrorView`),
`dialogs.dart` (`confirmDestructive`), `toasts.dart` (`runAction`) and
`voice_player.dart`.

## Interface

- `fikra_widgets.dart`: barrel that exports every file below except
  `photo_thumb.dart` and `voice_player.dart`. Screens import this barrel.
- `solid_surface.dart`: `SolidSurface(child, radius, padding, borderColor,
  borderWidth, color, width, height)`; an opaque surface plus line hairline.
- `glass.dart`: `Glass(child, radius, padding)` for existing floating controls
  only. Solid uses opaque surface; frosted/optical backing uses 90% surface and
  exactly one BackdropFilter.grouped with sigma 24. Non-overlapping siblings
  must share a BackdropGroup; overlapping lenses must not share that key.
- `glass_lens.dart`: `GlassLens(child, radius, opacity)` is an optical overlay above a
  backed Glass, with the package's LiquidGlassLens/LiquidGlassStyle API. Blur 7,
  surface tint 20%, saturation/refractionIndex 1.02, no dispersion, touch,
  adaptation or animation controllers. Lower tiers draw a visible capsule with
  Glass (solid/frosted), using a separate BackdropGroup because the lens overlaps
  its backing. Optical fading uses native package opacity and scaled blur/edge/
  shadow alpha, avoiding an isolating parent Opacity layer.
  Impeller samples the live backdrop; Skia without a capture view falls back
  to frosting; first-load shaders also briefly use that fallback. It is used by
  the floating tab bar and the debug glass preview.
- `glass_edge.dart`: one-pixel neutral/spectral rings, specular line,
  inset light/contact, lens inner rim/lower reflection and material shadows;
  no ShaderMask or saveLayer.
- `glass_quality.dart`: GlassTier {solid,frosted,optical}, debug/profile
  glassTierOverrideProvider, and glassTierProvider(disableAnimations).
  The single motion input is MediaQuery.disableAnimations. Effective tier is
  the minimum of watchdog ceiling, battery (solid), motion (frosted), and
  override. Release ignores overrides; no product override UI exists.
- `glass_power.dart`: fakeable GlassPowerSource; initial/broadcast state comes
  from fikra/glass_power. Unknown state caps at solid; missing plugin defaults
  to false for non-Android hosts, platform error to true. Disposal cancels the
  handler/subscription; stale initial responses cannot overwrite broadcasts.
  Riverpod 3 pauses the stream while nothing listens, so a bare
  `container.read(glassTierProvider(..))` stays solid; watch or listen to it.
- `glass_watchdog.dart`: fakeable GlassTimingsSource, session Notifier and fixed
  120-frame raster ring/scratch buffers. Only mounted, route-current,
  TickerMode-enabled Glass registers addTimingsCallback. Every 120 samples,
  p95 above 6.5*120/refreshHz ms drops one tier; no session promotion. Hiding
  all glass removes the callback and resets samples on reshow, not the ceiling.
  Raw timestamp subtraction avoids allocating a Duration per frame.
- `pearl_canvas.dart`: PearlCanvas behind screen content, static CustomPaint in
  RepaintBoundary. Exactly warm (0%,90%, stop52%) then cool (100%,97%, stop50%)
  over canvas, using CSS farthest-corner ellipse geometry. The existing tab
  transition veil reuses this paint with its shell anchor; no new animation.
- `glass_preview.dart`: release-excluded opt-in debug overlay and stationary
  GlassReviewPanel used by the screenshot/perf harness. No navigation gesture,
  floating Add button or phase-2 tab bar is implemented.
- `layout.dart`
  - `FikraScaffold({child, safeBottom = true})`: full-screen page outside the
    tab shell.
  - `FillScroll({child})`: fills the available height and centers its child,
    scrolling when short.
- `buttons.dart`
  - `FikraButton({label, onPressed, icon, style, expand = true, loading = false, horizontalPadding = 24, maxLines, growForText = false})`,
    with the constructors `FikraButton.secondary` and `FikraButton.danger`, and
    the enum `FikraButtonStyle { primary, secondary, danger }`.
  - `FikraIconButton({icon, label, onTap, size = 44})`.
- `fikra_field.dart`
  - `FikraField`: pill-shaped text input. Takes `controller`, `hint`, `icon`,
    `onChanged`, `onSubmitted`, `autofocus`, `error`, `keyboardType`,
    `obscure`, `textInputAction`, `maxLength`, `clearable = false`,
    `clearButtonKey`.
- `selectors.dart`
  - `FikraChip({label, selected = false, onTap})`.
  - `SegmentedPill({options, selected, onChanged, semanticLabels, segmentKeys, height})`.
- `status_badges.dart`
  - `FikraBadge({kind, label})` with `BadgeKind { demo, saved, processing, failed }`.
  - `StatusBanner({kind, message})` with `BannerKind { offline, error, info }`.
- `empty_states.dart`
  - `EmptyState({icon, title, description, action, padding})`.
  - `LoadErrorView({onRetry, description})`: optional localized feature-specific description, with the existing error title and retry presentation.
  - `AsyncBody<T>({value, data, onRetry})`: renders a Riverpod `AsyncValue<T>`.
- `sheets.dart`
  - `Future<T?> showFikraSheet<T>(context, {required title, required builder, tall = false})`.
  - `SheetOption({label, icon, onTap, danger = false, selected})`; `selected` exposes a single-choice sheet's current option to TalkBack.
- `dialogs.dart`
  - `Future<bool> confirmDestructive(context, {required title, required message, confirmLabel, danger = true})`,
    with `danger: false` drawing the confirm as the primary button (a confirmation that loses nothing),
    pushed through the file-private `_FikraDialogRoute`.
- `toasts.dart`
  - `void showToast(context, message, {String? actionLabel, VoidCallback? onAction})` and `toastActionDuration` (6 s).
  - `Future<bool> runAction(context, action, {success, failure})`.
- `photo_thumb.dart`
  - `PhotoThumb({required String path})`: square-cropped local photo, decoded at thumbnail size, with an icon when it can't be decoded.
- `voice_player.dart`
  - `VoicePlayer({required String path, required int durationMs, VoidCallback? onDelete, String? title, bool embedded = false})`:
    plays a local audio file, with play and pause, progress, and optional delete.

## Invariants

- SolidSurface rejects translucent custom fills. Reading cards, rows, dialogs,
  sheet content, fields, chat and settings must use it or opaque chip/surface
  decorations, never Glass. Glass has a RepaintBoundary and only adds blur
  when its effective tier needs it.
- `FikraButton` is disabled when `onPressed` is null or `loading` is true, and
  renders at 0.4 opacity. Compact buttons (`expand: false`) leave `alignment`
  null, because setting it would make the container fill the available width.
- `FikraChip` is read-only when `onTap` is null: 30 dp high with no selected
  semantics and no enlarged target. When tappable it is 36 dp high with a 48 dp
  target.
- `FikraBadge.label` overrides only the text. Colors still come from `kind`.
- `FikraIconButton` always has a hit area of at least 48 dp, and `label` is its
  screen reader label.
- `SegmentedPill` height defaults to `Pressable.minTargetSize + 10`, which keeps each
  segment at least 48 dp high; callers that grow with text scale pass a taller
  `height`. Labels are one line with ellipsis. `semanticLabels` replace the read
  text (for counts), and `segmentKeys` key each segment's semantics node. The selected pill follows `Directionality`.
  Under Reduce Motion it jumps instead of springing.
- `SegmentedPill` label colors are interpolated from the animation value, so a
  label is never light-on-light mid-slide.
- `NavigationInset(bottom, child)` exposes one shell-owned bottom clearance;
  `of(context)` returns zero outside the shell. It is exported by fikra_widgets.
- `FillScroll` pads by NavigationInset and uses `maxHeight - inset` (clamped at zero)
  as its minimum height, so its parent
  must give it a bounded height. `LoadErrorView`, and therefore the error branch
  of `AsyncBody`, inherits this requirement.
- Use `LoadErrorView` rather than `EmptyState` when a query failed, so a failure
  never looks like an empty list.
- `AsyncBody` checks `value.hasValue` before `value.hasError`, so available data
  wins over an error. While loading with no value it renders an empty box. Each
  branch carries a distinct `ValueKey` for `FikraSwitcher`.
- `EmptyState` includes the screen gutter in its default `padding`. Pass `padding`
  when the parent already applies one.
- `confirmDestructive` always resolves to a `bool`, and a dismissal resolves to
  false. It pushes on the root navigator and captures themes from the caller's
  context.
- `_FikraDialogRoute` uses the `FikraMotion` enter and exit tokens, or
  `reducedFade` with a plain fade under Reduce Motion.
- `showFikraSheet` resolves to the value popped by the sheet, or null. It pushes on
  the root navigator, so the sheet covers the shell's floating navigation instead of
  sitting under it and gets no `NavigationInset`. It uses no
  animation under Reduce Motion, and applies the keyboard inset as bottom padding.
  The default sheet fits its content in a scroll view. A `tall` sheet is 90 % of
  the height above the bottom safe area (less the keyboard inset when that is
  smaller), pads its footer above that safe area (not while the keyboard covers
  it), and gives `builder` that bounded height with no scroll view, for lazy
  lists with a footer. Non-tall sheets are unchanged. The shell's fill is the
  opaque `surface`, so its content sits in a transparent `Material` above that
  fill; otherwise ListTile and InkWell ink would paint under it, invisible (and
  ListTile asserts in debug).
- `confirmDestructive` resolves the default confirm label before pushing its route. `runAction` resolves its default failure message before awaiting.
- `runAction` catches every exception and error thrown by `action`. It returns
  true only after `action` completes, and shows `success` only then. It captures
  `ScaffoldMessenger.maybeOf(context)` before awaiting, so it never touches
  `context` afterward and shows no toast when no messenger exists.
- `showToast` uses `ScaffoldMessenger.of`, so a messenger must exist above
  `context`.
- `VoicePlayer` reads `path` once in `initState`. To play a different file, give
  the widget a new `Key` so its state is recreated.
- `VoicePlayer` uses `durationMs` as the total for both the progress ratio and
  the duration label, not a duration reported by the player. A `durationMs` of
  zero or less is treated as 1 for the ratio, and progress is clamped to 0..1.
- On a load failure `VoicePlayer` disables playback and shows an unavailable
  message instead of throwing. When playback completes it pauses and seeks to
  zero.

## Side Effects

- `VoicePlayer` creates its just_audio `AudioPlayer` lazily on first play and opens
  the file at `path` then. Unplayed previews allocate no native player. `dispose` cancels the player state subscription
  and releases the player.
- `showFikraSheet` and `confirmDestructive` push modal routes.
- `showToast`, and `runAction` whenever it has a message to show, hide the
  current snackbar and show a new one for 3 seconds.
- `runAction` executes the caller's `action`, which may have any side effect.
- `_FikraFieldState` owns a `FocusNode`, and `_SegmentedPillState` owns an
  unbounded `AnimationController`. Both are released in `dispose`.

## Localization and direction

- Shared labels, a11y text, errors, dialogs and playback states use `AppLocalizations` through `context.l10n`.
- Voice-player asymmetric insets use `EdgeInsetsDirectional`; segmented-control positioning already handles both directions.
- `FikraButton.horizontalPadding` defaults to 24. `growForText` is opt-in: it retains a 56 dp minimum and allows full multiline text with vertical padding and natural height. Other callers keep their fixed-height behavior. Rewrite actions use padding 8 and this option; their local layout chooses a measured row or a column without changing typography.

## Verification

- Run: `flutter analyze && flutter test`
- `test/motion_test.dart` covers the `confirmDestructive` results. No test refers
  to `showFikraSheet`, `runAction`, `showToast`, `AsyncBody`, `LoadErrorView`,
  `SegmentedPill` by name. `attachment_review_test.dart` drives real VoicePlayer widgets through the shared coordinator and verifies native allocation, pause/play ordering and disposal.

## Multi-recording arbitration

`VoicePlaybackCoordinator.start` serializes playback requests and awaits pausing the previous player before starting another. VoicePlayer uses the shared coordinator in Add, Edit and details, releases ownership on disposal and ignores queued starts after disposal. Late plugin disposal errors are caught during cleanup; no user action is performed from disposal. Playback widgets retain the public constructor and existing style. The public singleton `voicePlaybackCoordinator` exposes awaited `stop()` for recording. Loading is serialized with playback changes so a pending player cannot start after the mic. Idle queues are cleared. Unit tests verify queued starts; widget tests verify actual players, lazy allocation and disposal.

## Links phase 3

- `confirmDestructive` takes `danger` (default true, unchanged look). The note move passes `false` when no link would be removed.
- `SheetOption` wraps its label in `Flexible`, so a long label or large text wraps instead of overflowing the row ("Move to another project" overflowed with the test font).

## Undo toast (links phase 5a)

- `showToast` with both `actionLabel` and `onAction` adds one `SnackBarAction` (Undo) and stays `toastActionDuration` (6 s) instead of 3 s; without them it is unchanged. The messenger reads `persist` once, so the Undo toast is shown with `persist: true` and its text (`_TimedToast`) times it out itself: it follows `MediaQuery.accessibleNavigationOf` while shown, waiting for the next toast while a screen reader is on and leaving 6 s after it is turned off (or after it was shown). The timer does nothing once the button was pressed or a newer `showToast` replaced it. The SnackBar's own live region announces it. A newer toast replaces it (`hideCurrentSnackBar`), so its Undo can no longer be pressed.
- The action text uses `colors.accentLight`: the default (`inversePrimary`) was invisible on the white light-theme toast. `test/toast_test.dart` checks 4.5:1 contrast in both themes, the timings, the screen reader turned on and off mid-toast, and replacement.

## Pearl verification

`test/glass_quality_test.dart` covers each input/minimum, fake native stream,
watchdog windows/refresh budgets, callback lifecycle and no promotion.
`test/glass_widget_test.dart` covers opaque/no-blur reading, each material tier,
shared sibling backdrop keys, battery/reduced-motion caps, lens settings and
offstage listener removal. Screenshot gallery: light/dark Arabic side by side.
Product Glass consumers include the graph minimap, floating shell controls and
Links library search dock; reading content remains solid. Shell screens use NavigationInset.

## Floating navigation (redesign phase 2)

GlassEdge accepts an opacity multiplier for the lens release fade; it still owns
no ticker, shader mask or saveLayer. Unchanged default opacity preserves every
other material. The bar and Add share a backdrop key; an overlapping lens uses
its independent optical/frosted pass. FillScroll applies the shell clearance to
empty/error scrolling. Keyboard/reduce-motion selection stays with the caller.

## Clearable search fields (redesign phase 4)

When `FikraField.clearable` is true, `_FikraFieldState` listens to `controller`
and overlays a 48×48 dp `Pressable` (`Icons.close_rounded`, `clearSearch`
semantics) at the directional end inside `TextFieldTapRegion` whenever
`controller.text.isNotEmpty`. Tapping clears `controller`, calls
`onChanged?.call('')`, and re-requests focus only if `_focus` had it before the tap, so a field whose keyboard was scrolled away stays unfocused. The overlay sits outside
`SolidSurface`'s 1 dp border so the hit target stays at least 48×48 dp.

## Motion & delight (redesign phase 7)

- `glass_quality.dart`: adds `NavBarShrinkOverride` and `navBarShrinkEnabledProvider` (default `false`, ignored in `kReleaseMode`).
- `glass_preview.dart`: `GlassDebugOverlay` renders `debug-shrink-bar-toggle` (`FikraChip`) in debug/profile builds when `glassPreviewEnabledProvider` is enabled, toggling `navBarShrinkEnabledProvider`. `GlassReviewPanel` is unchanged.
- `selectors.dart`: `SegmentedPill` renders segment labels with `RollingText` so visible count changes roll changed digits while preserving TalkBack labels and Reduce Motion.
