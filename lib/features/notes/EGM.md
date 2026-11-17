# Notes

## Overview

The note list tab, mounted at `/notes` by `lib/app/router.dart`. It shows the selected project's notes grouped by calendar day, with client-side search.

## Interface

- `notes_screen.dart`
  - `NotesScreen`: `ConsumerStatefulWidget` with no parameters.
  - `enum NotesSort { newest, oldest }`, `NotesSortNotifier`, `notesSortProvider`: session-scoped sort choice.
- `note_card.dart`
  - `NoteCard({required Note note, required VoidCallback onTap, VoidCallback? onLongPress, bool? selected, NoteGroup? group})`: consumer list card with a single tap target; `selected` non-null means selection mode, `group` shows its tag.
- `notes_selection.dart`: `part of notes_screen.dart`, the private `_Selection` mixin (selection state, guards and the action bar).
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

## Selection and groups (links phase 5a)

- Selection mode: a long press on a card starts it with that note; then a tap (or long press) toggles a card. Cards show a check (`note-check-<id>`, checked/unchecked icon), a 2 dp accent border and `selected` semantics. `SelectionHeader` (shared) replaces `ProjectHeader` with the count (live region) and close (`selection-close`). Back (`PopScope(canPop: selection == null)`), close, deselecting the last note, a project switch (`ref.listen(selectedProjectProvider)`) and leaving the tab (`TickerMode.valuesOf(context).enabled` false in `didChangeDependencies`) all end it. Only listed notes stay selected: after each build `_keepVisible(_rowOf)` drops notes deleted, moved, or hidden by the search or the group filter (while the notes have loaded); an empty result ends selection. Choosing another group filter clears the selection. Starting a selection unfocuses search and hides the current toast, so an old Undo toast never covers the bar.
- The action bar (`SelectionActionBar`, shared) has `selection-link` (2–6 notes, `maxLinkTogether`; disabled with the `selection-note` explanation and a semantics hint above 6), `selection-group`, `selection-move`, `selection-delete`. Shared `noteSelectionActions` snapshots the selected notes in list order, claims `selectionBusyProvider` (shared with Undo: a second action, or one during a running Undo, does nothing; the bar is disabled meanwhile), hides the current toast (an older Undo can't be pressed during an action) and ends the selection only when the action reports success and the selection is still the one it started from (set identity), so Back plus a new long press during a slow action keeps the new selection. The flows live in `shared/selection_actions.dart`; action wiring/guard/snapshot lives once in `shared/note_selection_actions.dart`, also used by the graph. The notes screen keeps its selection lifecycle and set-identity completion callback.
- Groups: `groupsOfProjectProvider` (shared) feeds `GroupFilterRow` (hidden with no groups) and the card tags. The filter (`_filter`) shows the group with all its sub-groups, combines with search, resets on project switch and when its group is deleted (only once groups have loaded). A filter with no notes and no query shows the `group-empty` state. `_rebuildRows` also keys on the groups list identity and the filter.
- Verification: `test/selection_mode_test.dart`, `test/selection_actions_test.dart`, `test/note_groups_list_test.dart`; screenshots `45`–`56` in `test/screenshots/selection_test.dart`.

Phase 2 uses the existing batched project attachment stream to add trWorking in FikraBadge/processing style when any voice recording is queued or running. No per-card query or native job is started. Current displayText already participates in card previews and search, so appended transcripts are searchable through the existing path.

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.

## Floating navigation (redesign phase 2)

The lazy list adds NavigationInset.of(context) to its existing 24 dp bottom padding, so its final card scrolls above the bar, lens and Add button. The selection footer is offset by the same shared inset. Empty/error scroll states use FillScroll’s shared clearance. Keyboard opening reduces the inset to zero; no per-screen bar dimensions are used.

## Ordering & IA (redesign phase 4)

- `notes-search` (`FikraField`) passes `clearable: true` (`notes-search-clear`), clearing the query immediately; focus (and the keyboard) is re-requested only if the field had focus before the tap.
- Beside `notes-search`, `notes-sort` (`FikraIconButton` with `Icons.tune_rounded`, `notesSort` label) opens `showFikraSheet` with `notes-sort-newest` (`linksNewest`) and `notes-sort-oldest` (`linksOldest`), exposing `selected` semantics.
- `notesSortProvider` holds the choice in session memory (no schema or preference write). `_rebuildRows` keys on `sort`; `NotesSort.oldest` reverses the filtered list (`watchNotes` is `createdAt` DESC, so this is oldest first with ties mirroring the newest order) before day grouping, composing with search and group filters.

## Motion & delight (redesign phase 7)

- `NotesScreen` staggers at most the first 8 visible `NoteCard`s on a visible first load or visible project switch via `StaggerController` + `StaggeredEntry`, and opens `/note/${n.id}` with `extra: (n, origin)` from `NoteCard.onOpenWithOrigin` (`CardOrigin` with `FikraRadius.lg`) outside selection mode (`NoteCard` requires exactly one of `onTap` or `onOpenWithOrigin`).
