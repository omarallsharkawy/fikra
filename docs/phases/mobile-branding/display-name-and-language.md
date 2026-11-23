# Display name and English default

The user requested the visible name **FIKRAH** and English as the default app language. This follow-up applies the approved spelling to Android and localized branding, then changes unconfigured UI-language selection to English while preserving stored explicit choices.

The change uses the existing local settings stream and Riverpod locale provider. Explicit System selection is persisted separately from the missing setting; unsupported System locales fall back to English. No new dependencies, backend language contract, package identifier or data migration is introduced.

See [language semantics and walkthrough](../../features/app-language/defaults.md) and [brand resources](../../features/themed-brand-icons/appearance.md). Validation uses the limited development-machine settings established in [icon rollout](icon-rollout.md). Results will be recorded before merge.
