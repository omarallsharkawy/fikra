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
- `abstract interface class NotesRepository`, implemented by `LocalNotesRepository(FikraDatabase db)`: `watchNotes`, `watchNote`, `notesOf`, `notesWithStatus`, `create`, `markProcessing`, `markReady`, `markFailed`, `applyInsights`, `attachmentPaths`, `acceptRewrite`, `rejectRewrite`, `edit`, `restoreOriginal`, `delete`, `watchLinks`.
- `abstract interface class ChatRepository`, implemented by `LocalChatRepository(FikraDatabase db)`: `watch`, `add`, `clear`.

From `settings_repository.dart`:

- `enum AppTheme { system, light, dark }`: free of Flutter types; the app maps it to `ThemeMode`.
- `abstract interface class SettingsRepository`, implemented by `LocalSettingsRepository(FikraDatabase db, AttachmentStore files)`: `watchTheme`, `setTheme`, `wipeAllData`.
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
- `edit` keeps the current title when the new one is blank, and clears `editedText` when the text equals `originalContent`. It always drops any pending proposal, since a proposal made from the old text no longer applies; `pending` becomes `none`.
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
- `AppTheme.system` is stored as an absent row, and an unknown stored value reads as `system`.
- `wipeAllData` deletes rows children first in one transaction and keeps the theme. Files are purged only after the rows are gone, so a failure leaves only unreferenced files, and it surfaces as `WipeFilesException`. Retrying is safe.

Files and ordering:

- Rows are deleted before their files, and file cleanup is best effort. Anything missed is removed by `AttachmentStore.sweepOrphans`.
- `attachmentPaths` returns PDF, voice, and photo paths for all notes across all projects.
- `watchNotes` is newest first, and `ChatRepository.watch` is oldest first. `watchProjects` is ordered by creation time. `notesOf` has no defined order.

## Side Effects

- Reads and writes the `projects`, `notes`, `note_links`, `chat_entries` and `settings` tables through `FikraDatabase`. Project deletion relies on foreign-key cascades for notes, links and chat.
- `LocalProjectsRepository.delete` and `LocalNotesRepository.delete` remove attachment files through the static `AttachmentStore.deleteQuietly`, after the row delete.
- `LocalSettingsRepository.wipeAllData` deletes all attachment files and temp recordings through `AttachmentStore.purgeAll`.
- Child side effects are listed in each subdirectory's contract.

## Verification

- Run: `flutter analyze && flutter test`
