# Note Details

## Overview

The two pushed screens for one note: the read view at `/note/:id` and the editor at `/note/:id/edit`, both mounted by `lib/app/router.dart`. The read view shows the content, the AI rewrite proposal, attachments (PDF and photos open in another app), concepts, and related notes.

## Interface

- `note_details_screen.dart`
  - `NoteDetailsScreen({required String noteId, Note? initial})`: `ConsumerStatefulWidget`. `initial` is the note the caller already has.
- `edit_note_screen.dart`
  - `EditNoteScreen({required String noteId})`: `ConsumerStatefulWidget`.
- Consumes `noteProvider`, `linksOfProjectProvider`, `notesOfProjectProvider`, `notesRepoProvider`, and `noteProcessorProvider` from `lib/app/providers.dart`, `noteTitle` and `sourceIcons` from [shared](../shared/EGM.md), and `VoicePlayer` from `lib/core/widgets/voice_player.dart`.

## Invariants

- `initial` is displayed only until `noteProvider` has a value or an error.
- Related notes are read with the note's own `projectId`, never the `selected*` providers, so the screen works when the note is outside the selected project.
- Related notes render only when the note's status is `ProcessingStatus.ready`, with one row per other note (the first matching link wins).
- The improved/original toggle appears only when `Note.hasImprovedVersion` is true.
- The proposal card appears only when `rewrite == RewriteStatus.pending` and `proposedText` is non-null. `_busy` locks its buttons during a decision.
- After a delete, the screen pops only if the delete succeeded. Delete requires `confirmDestructive`.
- `EditNoteScreen` creates its text controllers once, from the first non-null note, starting from `title` and `displayText`. Later stream emissions do not overwrite them.
- Once the controllers exist, leaving the screen goes through `_requestLeave`: unsaved edits prompt for save, discard, or stay. `_requestLeave` does nothing while `_saving`.
- `_exit` sets `_allowPop` before popping on the next frame, bypassing the unsaved-changes guard.
- Field limits: title 80 characters, text 5000 characters.

## Side Effects

- Writes through `NotesRepository`: `edit`, `acceptRewrite`, `rejectRewrite`, `restoreOriginal`, and `delete`. `delete` also removes the note's files.
- `NotesRepository.edit` keeps the old title when the new one is blank, clears `editedText` when the text equals the original, and discards any pending rewrite proposal.
- Re-queues analysis through `NoteProcessor.retry` for a failed note.
- Plays voice attachments through `VoicePlayer`, and opens PDFs and photos through `openAttachment`.
- Pushes `/note/<id>/edit` and `/note/<other id>` (the latter with `extra`), pops routes, and shows toasts.

## Localization

All detail/editor actions, states and accessibility labels use `context.l10n`, including topics and related notes. Original-text guidance is shared for every note source. Rewrite buttons retain their existing placement and height with smaller inner padding and up to two lines for the keep-original label to fit approved copy. Date headers use `appClockProvider`.

## Verification

- Run: `flutter analyze && flutter test`
- `test/app_flow_test.dart` imports both screens directly.
