# Notes

## Overview

The note list tab, mounted at `/notes` by `lib/app/router.dart`. It shows the selected project's notes grouped by calendar day, with client-side search.

## Interface

- `notes_screen.dart`
  - `NotesScreen`: `ConsumerStatefulWidget` with no parameters.
- `note_card.dart`
  - `NoteCard({required Note note, required VoidCallback onTap})`: consumer list card with a single note-opening tap target.
- Consumes `selectedNotesProvider` from `lib/app/providers.dart`, `ProjectHeader` from [projects](../projects/EGM.md), and `noteTitle` and `sourceIcons` from [shared](../shared/EGM.md).

## Invariants

- Search matches a lower-cased substring of the note's title, display text, and concepts.
- Typing is debounced by 180 ms; clearing the query applies immediately.
- `_haystacks` is keyed by note ID and validated against the searchable field values, not `updatedAt`, so it never serves stale text. Entries are pruned when the cache exceeds twice the note count.
- `_rebuildRows` recomputes only when the list identity, the query, the locale, or the calendar day changes. The calendar-day check keeps relative day headers correct.
- Day grouping relies on `watchNotes` returning notes newest first (`createdAt` descending).
- The list is built lazily with `ListView.builder`. Note rows use `ValueKey(note.id)`, and `findChildIndexCallback` resolves them through `_rowOf`.
- The search field is hidden when the project has no notes. An empty project and an empty search result are separate states.
- Every point on a note card, including its PDF icon, opens the note through `onTap`. There is no `open-pdf-<id>` overlay or external-file action.
- `NoteCard`'s `switch` on `ProcessingStatus` is exhaustive. A ready note shows at most three concept tags.

## Side Effects

- Writes no application data.
- Pushes `/note/<id>` with the `Note` as `extra`, and navigates to `/add` from the empty state.
- Invalidates `selectedNotesProvider` on retry.

## Localization

All list/card labels, unnamed PDF format fallbacks and errors use `context.l10n`, with ICU counts and localized dates. Date-header caching includes locale and reads `appClockProvider`, so labels refresh on a runtime switch and screenshot grouping is stable.

## Verification

- Run: `flutter analyze && flutter test`
- `integration_test/stress_test.dart` imports `note_card.dart` directly.

Cards share `projectAttachmentsProvider(projectId)`, one joined attachment query per project, and render one icon per kind with a count only above one. A file-free/text-free note retains its source-icon fallback. `NoteCard` is now a ConsumerWidget; its constructor and row keys are unchanged. Stress seeds six attachments on every fourth note and times the same batched project query.
