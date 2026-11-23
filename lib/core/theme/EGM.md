# Theme

Pearl is the app's near-neutral colour system. Typography uses bundled Inter
for Latin text, NotoSansArabic for Arabic glyphs and Roboto as the final fallback.
Zero letter spacing, existing sizes, weights, radii, spacing and motion remain.
See `docs/features/inter-typography/font-usage.md` for sources and licensing.

`buildFikraTheme(Brightness)` installs `FikraPalette.light/dark` as a
ThemeExtension. `context.colors` requires this theme; `context.text` constructs
FikraText from it. Every palette field participates in constructor, copyWith
and lerp, including material alphas.

## Palette contract

- Opaque surfaces: canvas, surface, chip, selected. Reading content has no blur
  or translucent fill. line is the quiet hairline.
- Text: textPrimary, textSecondary, accent, onAccent. The old muted/meta/link,
  screen/glass, inverse-label and selected-gradient aliases are removed.
- One accent hue: blue. addTop → accent is the sole action gradient (145deg).
  `addGradient` replaces both primaryGradient and sendGradient. Selected controls
  use selected plus accent labels, never a gradient.
- Semantic status text/backgrounds: danger/dangerBg, success/successBg,
  warning/warningBg. They pass 4.5:1 on surface and their backgrounds in each
  theme. Status backgrounds are opaque. graphEdge and borderGraph are neutral.
- Material RGB: shadow, rim, highlight, lensRim, lensNeutral, bloomCool,
  bloomWarm, spectrumCool/Warm/Sage. All theme-dependent alpha parameters are
  explicit fields, including `glassBackingAlpha` (0.90 light, 0.72 dark). Shared `lensTintAlpha=.20` and
  `lensSpectrumGain=1.15` are constants. washAlpha=0 enforces the no-wash invariant; frameShadowAlpha is used only
  by the screenshot review frame, never product chrome. No finger marker exists.
- scrim and selection remain interaction overlays, never reading surfaces.
- Group markers: groupBlue, groupSage, groupSand, groupGray (stored group
  colour IDs 0..3). Calm, muted but distinct hues; each reaches 3:1 non-text
  contrast on surface and canvas in both themes (light gray was darkened in
  HSL lightness only, from #8E9599 to #878E92, to clear 3:1 on canvas).
- No purple, violet, lavender, magenta or pink palette values.
- Material scheme uses onAccent on primary/secondary; app-specific surfaces
  and labels always use these semantic tokens. No ripples; existing spring
  press feedback is unchanged.

## Verification

`test/pearl_contrast_test.dart` implements the spec's exact WCAG method: composite
sRGB, round channels to 8-bit, linearise at .04045, compare at normal-text AA
4.5:1 (3:1 non-text for the group markers on surface and canvas). It checks all reading fills, tab-bar glass (light 90% over black/white; dark 72% over dark-theme backdrops and primary text over white), solid sheet and toast text/icons (including opaque `SolidSurface` danger options), status pairs,
canvas and conservative overlapping blooms, and 1001 Add-gradient positions. PearlGradientAngle preserves physical CSS angles
for non-square capsules; an explicit geometry test covers 125/135/145 degrees.
`fikra_theme.dart` configures `snackBarTheme` (`colors.surface`, `StadiumBorder`, `insetPadding: EdgeInsets.fromLTRB(16, 5, 16, 12)`) for floating toast capsules.
Run `flutter analyze` and the tests outside the socket-restricted sandbox.

## Brand redesign (phase 1a)

- `FikraPalette` adds brand fill/ink/foreground/tint tokens: `brandLime`, `brandBlue`, `brandPurple`, `brandSlate`, plus `on*`, `*Fg`, and `*Tint` variants in constructor, `copyWith` and `lerp`.
- Neutral surfaces/text align to the dark (`#0E1013`/`#171A20`/`#22262F`/`#2E3440`, `#F3F5F7`/`#A1AAB8`) and light (`#F5F5F2`/`#FFFFFF`/`#ECEEEB`/`#DCDFE4`, `#14181F`/`#525B68`) concept palettes; `bloomCoolAlpha` and `bloomWarmAlpha` are zeroed.
- Semantic tokens remap to the brand (`accent` = `brandLimeFg`, `onAccent` = `#111214` dark / `#FFFFFF` light, `selected` = `#242B1A` dark / `#EEF6D4` light; Material `secondary` = `brandBlue`, `tertiary` = `brandPurple`).
- `FikraRadius` updates to `sm: 16`, `md: 18`, `lg: 20`, `xl: 24`, `xxl: 28`, `full: 999`. `FikraText` uses Inter with NotoSansArabic fallback and zero `letterSpacing`, raises `meta` to `12.5` sp, and bolds headings (`title` 28/w800, `cardTitleSmall` 17/w700, `body` 16/1.55, `caption` 14/1.5, `chip` 13/w600).
- `test/pearl_contrast_test.dart` asserts WCAG AA (`>= 4.5:1` text, `>= 3:1` large/icons) for every brand fill/ink, foreground-on-surface, and composited tinted badge pair in both themes plus typography bounds (`>= 12.5` sp).
