# Core

## Overview

App-wide presentation foundation for FIKRA: Arabic display formatting, plus the
theme, motion and shared-widget packages that feature screens are built from. It
holds no domain, storage or network logic.

## Interface

- `format.dart`
  - `Fmt` (`abstract final`), static methods returning display strings:
    - `time(DateTime)`: localized clock time.
    - `dayHeader(DateTime)`: today, yesterday, or a weekday and date.
    - `relative(DateTime)`: now, minutes ago, hours ago, then `dayHeader`.
    - `count(int n, {required one, required two, required few, required many})`:
      Egyptian-Arabic count phrasing.
    - `notes(int)` and `links(int)`: counts with a zero-state phrase.
    - `duration(int ms)`: `m:ss`.
    - `bytes(int)`: bytes, KB or MB with Arabic unit labels.
- Subpackages:
  - [motion](./motion/EGM.md): `FikraMotion`, `FikraSwitcher`, `FikraSprings`,
    `Pressable`, `FikraPageTransitionsBuilder`.
  - [theme](./theme/EGM.md): `buildFikraTheme`, `FikraPalette`, `FikraRadius`,
    `FikraSpace`, `FikraText`, and the `context.colors` and `context.text`
    getters.
  - [widgets](./widgets/EGM.md): `Glass`, `FikraButton`, `FikraField`,
    `FikraChip`, `FikraBadge`, `StatusBanner`, `EmptyState`, `SegmentedPill`,
    `SheetOption`, `FikraScaffold`, `FikraIconButton`, `AsyncBody`,
    `LoadErrorView`, `FillScroll`, `VoicePlayer`, and the functions
    `showFikraSheet`, `confirmDestructive`, `showToast`, `runAction`.

## Invariants

- `lib/core` imports nothing from `lib/app`, `lib/data` or `lib/features`. Its
  only external packages are Flutter, `intl`, `flutter_riverpod` and `just_audio`.
- Internal dependencies point one way: `widgets` depends on `theme`, `motion` and
  `format.dart`, and `theme` depends on `motion`. `motion` depends on no other
  core package.
- `Fmt.time`, and `Fmt.dayHeader` for dates before yesterday, require Arabic
  locale data to be loaded first, which `main` in `lib/main.dart` does with
  `initializeDateFormatting('ar')`. `Fmt.relative` needs it too when it falls
  through to `dayHeader`. Tests reaching these paths must initialize it as well.
- `Fmt` output keeps Western digits (0-9). Formatted dates pass through `_ascii`,
  which converts Eastern Arabic digits.
- `Fmt.count` treats 1 and 2 as whole phrases with no number. Values from 3 to 10
  use `few`, and every other value, including 0 and negatives, uses `many`. Callers
  needing a zero state must handle it first, as `Fmt.notes` and `Fmt.links` do.
- `Fmt.relative` treats any time less than one minute ago, including future
  times, as "now".
- Reduce Motion is honored throughout `motion` and `widgets`, using
  `MediaQuery.disableAnimations` as the single signal.

## Side Effects

- `Fmt.dayHeader` and `Fmt.relative` read the device clock through `DateTime.now`.
  `Fmt` is otherwise pure, and its `DateFormat` instances are lazily initialized
  static finals.
- Subpackage side effects are listed in their contracts. Runtime resources are
  limited to widget-owned controllers, a `WidgetsBindingObserver`, modal routes,
  snackbars, and the audio player in `VoicePlayer`.

## Verification

- Run: `flutter analyze && flutter test`
- Run from the repository root. No test calls `Fmt` directly.
