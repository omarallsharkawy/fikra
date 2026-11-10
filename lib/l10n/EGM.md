# Localization

## Overview

Arabic (RTL) and English (LTR) UI copy from `docs/plans/copy-glossary.md`. Arabic is the template locale. English is selected only for an English device unless the user explicitly chooses a language in Settings.

## File inventory and interface

- `app_ar.arb`, `app_en.arb`: the same glossary keys and typed placeholders. Counts and relative times use ICU plurals; Arabic has zero/one/two/few/many/other and English one/other with explicit `=0` where approved.
- `app_localizations.dart`, `app_localizations_ar.dart`, `app_localizations_en.dart`: Flutter gen-l10n output, checked in. Regenerate with `flutter gen-l10n`; never edit these files by hand.
- `localizations.dart`: exports `AppLocalizations` and the `BuildContext.l10n` extension.
- `demo_vocabulary.json`: Arabic/English topic and group labels from glossary section 13. These have no ARB keys per the glossary. Demo AI dictionary tuples reference these labels by internal ID.
- Root `l10n.yaml`: Arabic template, generated output in this directory, non-null localization getter.

## Invariants

- Copy approved Arabic and English exactly; do not rewrite in Dart. Section 15 keys are available for future work; the PDF viewer uses `pdfOpenElsewhere`, `pdfPageOf`, and `pdfLoadFailed` unchanged. Language settings use section 12.
- Use `context.l10n` in widgets and `lookupAppLocalizations(locale)` with an explicitly supplied or provider-resolved locale outside widgets.
- Language labels retain their endonyms. Counts, dates, times and sizes keep Western digits through `Fmt`; `intl` supplies locale date/time symbols and plural rules.
- Stored content and already analyzed topics/groups are never translated. Vocabulary localization applies only to new output.
- `hoursAgo` has no approved zero phrase; the zero branch uses its approved other phrase. Runtime relative formatting reaches it only for positive hours.

## Side effects

No runtime I/O in generated messages or the context extension. Demo AI reads the vocabulary JSON as a bundled asset and caches the decoded map.

## Verification

- `flutter gen-l10n`
- `flutter analyze && flutter test`
- `flutter test test/screenshots --run-skipped -t screenshots` renders `build/screenshots/{ar,en}/{dark,light}/` with fixed sample time.
