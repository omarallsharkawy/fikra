# Data Layer

## Overview

The app's offline data layer. Abstract repositories define what the UI can do
with projects, notes, chat and settings, and the `Local*` implementations back
them with the Drift database and the attachment store. `lib/app/providers.dart`
wires these together, and the UI updates through the repositories' Drift
streams.

## Interface

From `ids.dart`:

- `String newId()`: random UUID v4, used for every row and attachment file.

From `repositories.dart`:

- `typedef ProjectSummary = ({Project project, int noteCount})`
- `abstract interface class ProjectsRepository`, implemented by `LocalProjectsRepository(FikraDatabase db)`: `watchProjects`, `create`, `rename`, `delete`, `watchCurrentId`, `setCurrent`.
- `abstract interface class NotesRepository`, implemented by `LocalNotesRepository(FikraDatabase db, {deleteFiles})`: `watchNotes`, `watchNote`, `watchAttachments`, `watchProjectAttachments`, `notesOf`, `notesWithStatus`, `create`, `markProcessing`, `markReady`, `markFailed`, `applyInsights`, `attachmentPaths`, `acceptRewrite`, `rejectRewrite`, `edit`, `restoreOriginal`, `delete`, `watchLinks`.
- `abstract interface class ChatRepository`, implemented by `LocalChatRepository(FikraDatabase db)`: `watch`, `add`, `clear`.

From `settings_repository.dart`:

- `enum AppLanguage { system, ar, en }`: persisted language choice, free of Flutter types.
- `enum AppTheme { system, light, dark }`: free of Flutter types; the app maps it to `ThemeMode`.
- `abstract interface class SettingsRepository`, implemented by `LocalSettingsRepository(FikraDatabase db, AttachmentStore files)`: `watchTheme`, `setTheme`, `watchLanguage`, `setLanguage`, `wipeAllData`.
- `class WipeFilesException implements Exception`: wraps `cause`.

Subdirectories:

- [`./ai/EGM.md`](./ai/EGM.md): the `AiService` seam and its demo implementation.
- [`./demo/EGM.md`](./demo/EGM.md): `seedDemoProject`.
- [`./files/EGM.md`](./files/EGM.md): `AttachmentStore`, which owns attachment files, and `openWithSystem`.
- [`./local/EGM.md`](./local/EGM.md): `FikraDatabase`, tables, enums and migrations.
- [`./processing/EGM.md`](./processing/EGM.md): `NoteProcessor`, the serial AI queue.

## Invariants

Notes:

- `create` trims title and text and starts the note as `processing`, `RewriteStatus.none`, with empty concepts. Saving and AI completion are separate states.
- Every update through `_write` bumps `updatedAt`.
- `originalText` is never changed after `create`.
- `edit` keeps a title when the replacement is blank. Changed body text retains the existing edit/original behavior and clears a pending proposal; attachment-only edits leave analysis and proposals intact. It never calls AI. A draft with no body text and no files throws `EmptyNoteException`, regardless of title.
- `edit(..., attachments:)` atomically replaces the attachment draft with the text edit, validates existing attachment IDs belong to that note, and deletes removed disk files only after commit. Cleanup catches all errors so a successful transaction never triggers copy rollback; leftovers are swept later. The optional `deleteFiles` callback is a cleanup-failure test seam. Omitting attachments leaves them intact. Source is recomputed from the resulting files within the same transaction, independently of analysis.
- `acceptRewrite` moves `proposedText` to `editedText`, and is a no-op without a proposal. `acceptRewrite` and `edit` throw if the note does not exist.
- `restoreOriginal` clears only `editedText`.

`applyInsights` (one transaction, and a no-op if the note was deleted):

- A non-blank live title is kept. `extractedText` is never written.
- A proposed rewrite is discarded when the user edited the note since `basis`, or when `editedText` is already set.
- Concepts are capped at 8.
- AI output is untrusted. Links are kept only for targets in the same project, with no self links and no duplicates, and at most 8 per note. Strength is clamped to 0..1 and non-finite values become 0. Labels are cut to 80 characters.
- A note owns only its outgoing edges: previous links with this `source_id` are replaced, and incoming links are left alone.

Projects and settings:

- `ProjectsRepository.create` trims the name and makes the new project current.
- Deleting the current project selects the oldest remaining project, or clears the selection if none remain. This happens in the same transaction as the delete.
- The `current_project` settings key is duplicated as `LocalProjectsRepository._currentKey` and `LocalSettingsRepository._currentProjectKey`. The two must stay equal.
- Theme and language each store `system` as an absent row; unknown values read as `system`. Language uses the existing settings table, with no schema change.
- `wipeAllData` deletes rows children first in one transaction and keeps the theme and language. Files are purged only after the rows are gone, so a failure leaves only unreferenced files, and it surfaces as `WipeFilesException`. Retrying is safe.

Files and ordering:

- Rows are deleted before their files, and file cleanup is best effort. Anything missed is removed by `AttachmentStore.sweepOrphans`.
- `attachmentPaths` returns every new-table path across projects. Migration completes before repository queries; a failed opening prevents startup sweeping. Legacy columns are migration-only.
- `watchNotes` is newest first, and `ChatRepository.watch` is oldest first. `watchProjects` is ordered by creation time. `notesOf` has no defined order.

## Side Effects

- Reads and writes the `projects`, `notes`, `note_attachments`, `note_links`, `chat_entries` and `settings` tables through `FikraDatabase`. Project deletion relies on foreign-key cascades for notes, links and chat.
- `LocalProjectsRepository.delete` and `LocalNotesRepository.delete` remove attachment files through the static `AttachmentStore.deleteQuietly`, after the row delete.
- `LocalSettingsRepository.wipeAllData` deletes all attachment files and temp recordings through `AttachmentStore.purgeAll`.
- Child side effects are listed in each subdirectory's contract.

## Verification

- Run: `flutter analyze && flutter test`

## Attachment drafts and queries

`attachment_draft.dart` defines `AttachmentDraft` (saved ID or new source path), `EmptyNoteException`, and `saveAttachmentDraft`. The helper copies each new source in draft order, calls the atomic repository operation, and deletes only its new destination files if any copy or commit fails. Sources remain available for retry. `create(attachments:)` writes the note and attachments in one transaction and omits legacy fields.

`watchAttachments(noteId)` is an indexed ordered stream. `watchProjectAttachments(projectId)` performs one joined query and groups rows by note ID. Cards share its provider; they never start one query per note. `_filePaths` joins the new table for note/project deletion; wipe relies on cascades and purges after commit.
