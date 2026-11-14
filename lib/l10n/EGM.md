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

Multi-attachment editing adds `removeAttachmentBody` (deferred removal confirmation) and `emptyNoteBlocked` (empty edit draft). Other actions reuse existing keys. Generated files are refreshed with gen-l10n.

`pdfPasswordProtected` gives a specific locked-PDF message and suggests opening it in another app. Password failures omit retry; all ordinary PDF errors keep `pdfLoadFailed`. Both ARBs and generated files are updated.

Review follow-up replaces `removeAttachmentBody` and `emptyNoteBlocked` with the exact requested Arabic/English wording. The former is only shown for saved files; the latter explicitly asks for text or a file and does not accept a title alone. No new keys in this follow-up.

Links phase 2 adds glossary section 16: `noteLinksHeader`, `linkToNote`, `noteLinksEmpty`, `noteLinksLoadFailed`, `linkSuggestedTag`, `linkRowA11y`, `suggestedLinkA11y`, `acceptLink`, `acceptLinkA11y`, `rejectLink`, `rejectLinkA11y`, `linkOptionsA11y`, `linkOptionsTitle`, `editLinkReason`, `removeLink`, `removeLinkTitle`, `removeLinkBody`, `removeLinkConfirm`, `linkRemoved`, `linkUpdateFailed`, `linkReasonHint`, `alreadyLinked`, `linkPickerEmpty`, `linkFailed`, and the plurals `linkSelected` and `notesLinked`. `relatedNotesHeader`, `relatedLoadFailed`, `relatedEmpty` and `relatedRowA11y` were removed; section 16 replaces them.

Links phase 3 adds glossary section 17: `moveToProject`, `moveNoOtherProject`, `moveNoteTitle`, `moveNoteBody`, `moveNoteBodyNoLinks`, `moveConfirm`, `noteMoved`, `moveNoteFailed`, the plurals `suggestionsCount` and `filesCount`, the joiners `listTwo` and `listThree`, `deleteProjectEmptyBody`, `firstProjectNameHint`, `sourceMissing` and `sourceMissingA11y`. Changed: `deleteProjectBody` now takes `{items}`, and `projectNameHint` is "اسم المشروع" / "Project name" (the example moved to `firstProjectNameHint`). Removed: `deletedNote` and `sourceDeletedA11y`. Count phrases go through `Fmt` (Western digits) and zero counts are left out of sentences.

Review follow-up: adds `deleteProjectEmptyChatBody` (a project with no notes but an Ask chat); Arabic `linkOptionsA11y` is now «خيارات الرابط مع «{title}»» and `linkPickerEmpty` ends «تربطها بالملاحظة دي.». Project-name placeholders hold no isolate characters; callers pass `Fmt.isolate(name)`.

Links phase 5a adds glossary section 18 (selection, link together, groups, moving and deleting several notes, group rules): `selectedCount`, `linksAdded`, `moveNotesBody`, `moveNotesBodyNoLinks` and `deleteNotesBody` are plurals (Arabic zero/one/two/few/many/other); the rest are plain or take placeholders (`notes`, `group`, `project`, `parent`, `color`, `max`, `lost`). Names go through `Fmt.isolate`, counts through `Fmt`. `undo` and `undoFailed` serve every Undo toast. Seven `groupRule*` keys give each `GroupRuleReason` its own message. No existing key changed.

Phase 5b adds three keys in both ARBs and regenerated lookups: suggestedTopics (مواضيع مقترحة / Suggested topics), makeTopicGroup (حوّل «{topic}» لمجموعة / Make {topic} a group), graphGroupA11y (مجموعة «{group}»، {notes} / Group {group}, {notes}). Group names and topic names stay user content; counts, options, grouping success and Undo reuse the existing messages.

Phase 5b review adds moreTopics (باقي المواضيع / More topics), moreTopicsCount (Arabic zero/one/two/few/many/other and English one/other) and graphNoteInGroup ({title}، في مجموعة «{group}» / {title}, in group {group}). Existing moreGroups strings remain public but the graph’s hidden-topic overflow uses topics. Both ARBs and generated lookups are regenerated; no existing key is renamed.

Links phase 6 (graph navigation) adds `graphSearchHint` («دوّر في الرسم» / "Search the graph"), `graphSearchEmpty`, `graphSearchNote`, `graphSearchLink`, `graphSearchGroup`, `graphSearchLimited`, `graphNavigateGroup(group)` (chip label that says it does not filter), `graphCollapseGroup(group)`, `graphExpandGroup(group)`, `graphCollapsedGroup(group, notes)` and `graphMinimap`. Names inside sentences go through `Fmt.isolate`. These keys are not in the glossary yet. The same follow-up changes `deleteProjectBody` to «والمحادثة كمان» (singular, matching the single chat) in the ARB and in the glossary's section 5 rows that quote it.
