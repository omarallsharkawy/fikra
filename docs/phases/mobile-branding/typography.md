# Mobile branding: English typography

Scope: bundle Inter for English and preserve existing NotoSansArabic rendering,
following the user’s explicit font choice. Display name and language behavior
were completed separately in PR #5. No backend or content migration is involved.

Implementation uses the same font family and fallback chain in shared tokens and
Material themes. Static upstream weights avoid platform-dependent synthesis for
Latin headings. Real fonts are loaded in layout tests, including product routes.

## Verification

- `flutter analyze --no-pub`: no issues.
- 52 focused tests passed: real-font shaping/English metrics, typography/contrast,
  branded headers, welcome, product navigation, localization, 360dp large text
  (1.3x/2.0x, Arabic/English, light/dark), TalkBack guidelines and semantics.
- Profile ARM64 APK built successfully in 107.4 seconds with low priority,
  affinity to two CPU cores, one Gradle worker and a 1 GiB Gradle heap.
- APK font manifest declares all five Inter weights and the original four Arabic
  weights. Each bundled Inter face and its license matches the source bytes.
- APK SHA-256: `4c95721502855a0c6b1e04f97a500fc74fdaf3236570412f88e5ceebe6c334e9`.
- Updated the attached Xiaomi M2010J19SG via ADB and cold-launched successfully.
  The account screen was visually checked: Inter English copy, FIKRAH heading
  and brand artwork render without clipping. App data/preferences were retained.
- Application label remains FIKRAH; the package identifier is unchanged.

The installed APK contains source commit `173946f`; the following documentation
commit records verification only. Logs and device screenshots are local ignored
artifacts under `build/validation/`. Existing user documentation moves are excluded.
