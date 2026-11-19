# Theme

Pearl is the app's Arabic-first, near-neutral colour system. Typography remains
NotoSansArabic with Roboto fallback, no letter spacing, and the existing sizes,
weights, radii, spacing and motion.

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
