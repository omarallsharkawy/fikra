# Notes

## Overview

The note list tab, mounted at `/notes` by `lib/app/router.dart`. It shows the selected project's notes grouped by calendar day, with client-side search.

## Interface

- `notes_screen.dart`
  - `NotesScreen`: `ConsumerStatefulWidget` with no parameters.
- `note_card.dart`
  - `NoteCard({required Note note, required VoidCallback onTap})`: stateless list card. Its PDF hit area needs a `ProviderScope`.
- Consumes `selectedNotesProvider` from `lib/app/providers.dart`, `ProjectHeader` from [projects](../projects/EGM.md), and `noteTitle` and `sourceIcons` from [shared](../shared/EGM.md).

## Invariants

- Search matches a lower-cased substring of the note's title, display text, and concepts.
- Typing is debounced by 180 ms; clearing the query applies immediately.
- `_haystacks` is keyed by note ID and validated against the searchable field values, not `updatedAt`, so it never serves stale text. Entries are pruned when the cache exceeds twice the note count.
- `_rebuildRows` recomputes only when the list identity, the query, or the calendar day changes. The calendar-day check keeps relative day headers correct.
- Day grouping relies on `watchNotes` returning notes newest first (`createdAt` descending).
- The list is built lazily with `ListView.builder`. Note rows use `ValueKey(note.id)`, and `findChildIndexCallback` resolves them through `_rowOf`.
- The search field is hidden when the project has no notes. An empty project and an empty search result are separate states.
- On a card with a PDF, an invisible area over the top-start corner opens the file instead of the note.
- `NoteCard`'s `switch` on `ProcessingStatus` is exhaustive. A ready note shows at most three concept tags.

## Side Effects

- Writes no application data.
- Pushes `/note/<id>` with the `Note` as `extra`, and navigates to `/add` from the empty state.
- Invalidates `selectedNotesProvider` on retry.

## Verification

- Run: `flutter analyze && flutter test`
- `integration_test/stress_test.dart` imports `note_card.dart` directly.
