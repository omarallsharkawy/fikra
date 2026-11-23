# Display name and English default

The user requested the visible name **FIKRAH** and English as the default app language. This follow-up applies the approved spelling to Android and localized branding, then changes unconfigured UI-language selection to English while preserving stored explicit choices.

The change uses the existing local settings stream and Riverpod locale provider. Explicit System selection is persisted separately from the missing setting; unsupported System locales fall back to English. No new dependencies, backend language contract, package identifier or data migration is introduced.

See [language semantics and walkthrough](../../features/app-language/defaults.md) and [brand resources](../../features/themed-brand-icons/appearance.md). Validation uses the limited development-machine settings established in [icon rollout](icon-rollout.md).

## Validation

- Focused settings, localization, welcome and product-navigation checks: 25 passed.
- Full regression: 822 passed, 15 skipped, no failures (6m 38s).
- Flutter analysis: no issues.
- Android profile APK built from application source `7dc6e44` in 168 seconds with two allowed CPU cores, low CPU/I/O priority, one Gradle/native worker and a 1024 MiB Java heap.
- APK SHA-256: `52042099ec143d5d943f944f08c74448b09cc605f9f66f6ab18487321e74edce`.
- `aapt2` confirmed `application-label:'FIKRAH'`. USB update installation succeeded on the Xiaomi M2010J19SG; device App info showed FIKRAH and the application launched successfully with an English interface. No app data or language preference was cleared for the check.
- The fresh Arabic-device default is covered by the widget test, separately from the existing phone's appearance/language state. Voice/transcription language is unchanged.
