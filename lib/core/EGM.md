# Core

## Overview

App-wide presentation foundation for FIKRA: localized display formatting, plus the
theme, motion and shared-widget packages that feature screens are built from. It
holds no domain, storage or network logic.

## Interface

- `format.dart`: `Fmt` static methods return display strings.
  - `time(AppLocalizations, DateTime)`: locale-specific 12-hour clock.
  - `dayHeader(AppLocalizations, DateTime, {DateTime? now})`: today, yesterday, or weekday/date.
  - `relative(AppLocalizations, DateTime, {DateTime? now})`: localized ICU minutes/hours or day header.
  - `notes(AppLocalizations, int)` and `links(AppLocalizations, int)`: ICU plural messages, including zero.
  - `duration(int ms)`: numeric `m:ss`.
  - `bytes(AppLocalizations, int)`: localized bytes/KB/MB using `NumberFormat`.
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
  external packages are Flutter, `intl`, `flutter_riverpod` and `just_audio`; localized strings come from `lib/l10n`.
- Internal dependencies point one way: `widgets` depends on `theme`, `motion` and
  `format.dart`, and `theme` depends on `motion`. `motion` depends on no other
  core package.
- Date symbols are initialized by `main` using `initializeDateFormatting()`; standalone tests using dates initialize them too.
- Formatting always keeps Western digits, including localized dates and sizes. Counts use generated ICU forms; Arabic 103 uses `few`.
- `Fmt.relative` treats less than one minute, including future dates, as now.
- Reduce Motion is honored throughout `motion` and `widgets`, using
  `MediaQuery.disableAnimations` as the single signal.

## Side Effects

- `Fmt.dayHeader` and `Fmt.relative` read the device clock through `DateTime.now`.
  unless `now` is supplied. `Fmt` is otherwise pure.
- Subpackage side effects are listed in their contracts. Runtime resources are
  limited to widget-owned controllers, a `WidgetsBindingObserver`, modal routes,
  snackbars, and the audio player in `VoicePlayer`.

## Verification

- Run: `flutter analyze && flutter test`
- `test/localization_test.dart` covers plural forms, date/time and size formatting.
