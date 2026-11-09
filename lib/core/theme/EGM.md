# Theme

## Overview

Design tokens and the Material theme for FIKRA: a semantic color palette with
dark and light variants, radius and spacing scales, the text styles, and the
`ThemeData` factory that installs them. Widgets reach the tokens through the
`context.colors` and `context.text` extension getters.

## Interface

- `fikra_theme.dart`
  - `ThemeData buildFikraTheme(Brightness brightness)`: Material 3 theme with
    the matching `FikraPalette` installed as a theme extension. Called from
    `lib/app/app.dart` for both `theme` and `darkTheme`.
- `tokens.dart`
  - `FikraPalette` (`ThemeExtension<FikraPalette>`, `@immutable`), with the
    constants `FikraPalette.dark` and `FikraPalette.light`, plus `copyWith` and
    `lerp`. Fields:
    - Surfaces: `canvas`, `screen`, `glass`, `glassHighlight`, `pressed`,
      `scrim`, `selection`.
    - Text: `textPrimary`, `textSecondary`, `textBodyMuted`, `textPlaceholder`,
      `textMeta`, `textOnLight`, `textLink`, `textOnSelected`, `textOnSend`.
    - Borders: `border`, `borderGraph`, `borderFocus`.
    - Accent and selection: `accent`, `accentLight`, `selectedStart`,
      `selectedEnd`, `graphEdge`.
    - Status: `danger`, `dangerBg`, `success`, `successBg`, `warning`.
    - Gradients (`LinearGradient`): `screenGradient`, `glassGradient`,
      `selectedGradient`, `primaryGradient`, `sendGradient`.
  - `extension FikraThemeContext on BuildContext`: `colors` (`FikraPalette`) and
    `text` (`FikraText`).
  - `FikraRadius` (`abstract final`): `sm`, `md`, `lg`, `xl`, `xxl`, `full`.
  - `FikraSpace` (`abstract final`): `s4`, `s8`, `s10`, `s12`, `s16`, `s20`,
    `s24`, `s32`, plus the named sizes `screen` (gutter), `button`, `nav`,
    `field` and `hairline`.
  - `FikraText(FikraPalette colors)`: `TextStyle` getters `title`, `cardTitle`,
    `cardTitleSmall`, `section`, `bodyLarge`, `answer`, `body`, `field`,
    `caption`, `nav`, `button`, `chip`, `meta`. The font family constant is
    `FikraText.family`.

## Invariants

- `context.colors` force-unwraps the theme extension. Any widget using it, and
  any widget test, needs a `ThemeData` from `buildFikraTheme` (or one that
  otherwise carries a `FikraPalette`) above it.
- A new `FikraPalette` field must be added to the constructor, `dark`, `light`,
  `copyWith` and `lerp`. Theme animation relies on `lerp` covering every field.
- Color literals use the `AARRGGBB` form. `FikraPalette.dark` preserves the
  original FIKRA tokens exactly.
- `FikraPalette.light` uses darker accent and status colors for AA contrast.
  Check contrast when changing them.
- `sendGradient`, `textOnSelected` and `textOnSend` have the same values in both
  palettes.
- `textOnLight` is a legacy name: it is the inverse label color for the primary
  button, so it is dark in the dark palette and light in the light palette.
- Do not add letter spacing to `FikraText` styles, because negative tracking
  breaks Arabic letter joining.
- `FikraText` and `buildFikraTheme` set `NotoSansArabic` with a `Roboto`
  fallback, because the Arabic font has no Latin glyphs. The font family name
  must match the `fonts:` entry in `pubspec.yaml`, which declares weights 400,
  500, 600 and 700.
- The theme disables ripples (`NoSplash.splashFactory` with transparent splash,
  highlight and hover colors). Press feedback belongs to `Pressable` in
  [motion](../motion/EGM.md).
- `dialogTheme` and `bottomSheetTheme` use transparent backgrounds with no
  elevation. `confirmDestructive` and `showFikraSheet` in
  [widgets](../widgets/EGM.md) paint their own surfaces.
- `pageTransitionsTheme` registers `FikraPageTransitionsBuilder` for
  `TargetPlatform.android` only.

## Side Effects

- None. Tokens are constants, and `buildFikraTheme` is a pure factory.
- `context.colors` and `context.text` read `Theme.of`, so the calling widget
  rebuilds when the theme changes. Each `context.text` read allocates a new
  `FikraText`.

## Verification

- Run: `flutter analyze && flutter test`
- `test/motion_test.dart` builds screens with `buildFikraTheme`. No test asserts
  palette values or `lerp`.
