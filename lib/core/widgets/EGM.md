# Widgets

## Overview

Shared UI kit for FIKRA screens: glass surfaces, buttons, fields, chips, badges,
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
- `glass.dart`
  - `Glass`: gradient surface with a hairline border. Takes `child`, `radius`,
    `padding`, `borderColor`, `borderWidth`, `gradient`, `color`, `width`,
    `height`.
- `layout.dart`
  - `FikraScaffold({child, safeBottom = true})`: full-screen page outside the
    tab shell.
  - `FillScroll({child})`: fills the available height and centers its child,
    scrolling when short.
- `buttons.dart`
  - `FikraButton({label, onPressed, icon, style, expand = true, loading = false, horizontalPadding = 24, maxLines})`,
    with the constructors `FikraButton.secondary` and `FikraButton.danger`, and
    the enum `FikraButtonStyle { primary, secondary, danger }`.
  - `FikraIconButton({icon, label, onTap, size = 44, solid = false})`.
- `fikra_field.dart`
  - `FikraField`: pill-shaped text input. Takes `controller`, `hint`, `icon`,
    `onChanged`, `onSubmitted`, `autofocus`, `error`, `keyboardType`,
    `obscure`, `textInputAction`, `maxLength`.
- `selectors.dart`
  - `FikraChip({label, selected = false, onTap})`.
  - `SegmentedPill({options, selected, onChanged})`.
- `status_badges.dart`
  - `FikraBadge({kind, label})` with `BadgeKind { demo, saved, processing, failed }`.
  - `StatusBanner({kind, message})` with `BannerKind { offline, error, info }`.
- `empty_states.dart`
  - `EmptyState({icon, title, description, action, padding})`.
  - `LoadErrorView({onRetry})`.
  - `AsyncBody<T>({value, data, onRetry})`: renders a Riverpod `AsyncValue<T>`.
- `sheets.dart`
  - `Future<T?> showFikraSheet<T>(context, {required title, required builder})`.
  - `SheetOption({label, icon, onTap, danger = false})`.
- `dialogs.dart`
  - `Future<bool> confirmDestructive(context, {required title, required message, confirmLabel})`,
    pushed through the file-private `_FikraDialogRoute`.
- `toasts.dart`
  - `void showToast(context, message)`.
  - `Future<bool> runAction(context, action, {success, failure})`.
- `photo_thumb.dart`
  - `PhotoThumb({required String path})`: square-cropped local photo, decoded at thumbnail size, with an icon when it can't be decoded.
- `voice_player.dart`
  - `VoicePlayer({required String path, required int durationMs, VoidCallback? onDelete, String? title, bool embedded = false})`:
    plays a local audio file, with play and pause, progress, and optional delete.

## Invariants

- `Glass.color`, when set, replaces the gradient entirely. `gradient` and the
  default `glassGradient` apply only when `color` is null.
- `FikraButton` is disabled when `onPressed` is null or `loading` is true, and
  renders at 0.4 opacity. Compact buttons (`expand: false`) leave `alignment`
  null, because setting it would make the container fill the available width.
- `FikraChip` is read-only when `onTap` is null: 30 dp high with no selected
  semantics and no enlarged target. When tappable it is 36 dp high with a 48 dp
  target.
- `FikraBadge.label` overrides only the text. Colors still come from `kind`.
- `FikraIconButton` always has a hit area of at least 48 dp, and `label` is its
  screen reader label.
- `SegmentedPill` height is `Pressable.minTargetSize + 10`, which keeps each
  segment at least 48 dp high. The selected pill follows `Directionality`.
  Under Reduce Motion it jumps instead of springing.
- `SegmentedPill` label colors are interpolated from the animation value, so a
  label is never light-on-light mid-slide.
- `FillScroll` uses the incoming `maxHeight` as its minimum height, so its parent
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
- `showFikraSheet` resolves to the value popped by the sheet, or null. It uses no
  animation under Reduce Motion, and applies the keyboard inset as bottom padding.
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

- `VoicePlayer` creates one just_audio `AudioPlayer` per state and opens the file
  at `path` during `initState`. `dispose` cancels the player state subscription
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
- `FikraButton.horizontalPadding` defaults to 24 in every constructor. Rewrite actions use 8, and the keep-original label allows two lines, so the approved labels fit in the existing two-button row without changing button height, typography or outer layout.

## Verification

- Run: `flutter analyze && flutter test`
- `test/motion_test.dart` covers the `confirmDestructive` results. No test refers
  to `showFikraSheet`, `runAction`, `showToast`, `AsyncBody`, `LoadErrorView`,
  `SegmentedPill` or `VoicePlayer` by name.
