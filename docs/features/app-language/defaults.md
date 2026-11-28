# Default interface language

The application opens in **English** when no UI-language preference is stored, including on Arabic devices. Missing or invalid settings and unavailable device locales resolve to English. FIKRAH is the display name in both interface languages.

Previously saved Arabic and English choices remain effective. Users can still select Arabic, English or System from appearance/language settings. System is now stored explicitly as `language=system`; it follows an Arabic device locale and otherwise uses English. This choice survives reopening and local-data cleanup like other preferences.

Older builds encoded System by removing the row. Such an absent row cannot be distinguished from an unconfigured installation, so it now receives the requested English default. No database migration or content translation occurs. Existing notes, sample text, recordings and transcription-language choices are not changed by UI-language selection.

This is a Flutter interface preference; it does not finalize the backend's unresolved supported-language requirements or speech/model coverage.

## Checks and manual verification

Repository tests cover missing/invalid preference fallback and persistence of explicit Arabic, English and System selections. A widget test starts with an Arabic device and no saved language, verifies English/LTR, then switches between explicit Arabic, System and English while the app is running. Unsupported System locales return to English.

For manual verification, open a fresh installation and confirm English. In Account, choose Arabic and reopen the application; Arabic should remain selected. Choose System and change the device locale to a supported language if desired. Existing installations retain their saved preference; do not clear private app data merely to test the default.
