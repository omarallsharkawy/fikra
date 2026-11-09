# Local Database

## Overview

The Drift/SQLite schema for the offline app: tables, enums, the migration path
and the `Note` and `ChatEntry` read helpers. All persistence in
[`../EGM.md`](../EGM.md) goes through `FikraDatabase`.

`database.g.dart` is generated from `database.dart`. Do not edit it by hand;
regenerate it with `dart run build_runner build -d`.

## Interface

From `database.dart`:

- Enums: `NoteSource { text, voice, pdf }`, `ProcessingStatus { processing, ready, failed }`, `RewriteStatus { none, pending, accepted, rejected }`.
- `class FikraDatabase`
  - `FikraDatabase([QueryExecutor? executor])`: defaults to `driftDatabase(name: 'fikra')`; tests inject an executor.
  - `schemaVersion` is 4.
- `extension NoteX on Note`: `conceptList`, `originalContent`, `displayText`, `hasPdf`, `hasVoice`, `imageList`, `hasImages`, `filePaths`, `hasImprovedVersion`.
- `extension ChatEntryX on ChatEntry`: `sourceList`, `isUser`.

Tables (Drift data class in parentheses):

| SQL table      | Drift class             | Primary key | Foreign keys (all `ON DELETE CASCADE`)                        |
| -------------- | ----------------------- | ----------- | ------------------------------------------------------------- |
| `projects`     | `Projects` (`Project`)  | `id`        | None                                                          |
| `notes`        | `Notes` (`Note`)        | `id`        | `project_id` to `projects`                                    |
| `note_links`   | `NoteLinks` (`NoteLink`) | `id`       | `project_id` to `projects`; `source_id`, `target_id` to `notes` |
| `chat_entries` | `ChatEntries` (`ChatEntry`) | `id`    | `project_id` to `projects`                                    |
| `settings`     | `Settings` (`Setting`)  | `key`       | None                                                          |

Indexes: `notes_project_created`, `notes_status`, `note_links_project`,
`note_links_source`, `note_links_target`, `chat_entries_project_created`.

## Invariants

Column semantics:

- `Notes.originalText` is exactly what the user typed and is never overwritten.
- `Notes.editedText` is the version shown when set: an accepted AI rewrite or a user edit. `Notes.proposedText` is an AI rewrite awaiting accept or reject.
- `Notes.source` names the main content: `pdf` when a PDF is attached (a voice memo may sit beside it), `voice` for a recording alone, otherwise `text`.
- Since schema v2, `attachmentPath`, `attachmentName` and `attachmentBytes` describe the PDF only. A recording lives in `voicePath` with its length in `durationMs`.
- `Notes.concepts`, `Notes.imagePaths`, and `ChatEntries.sourceIds` are `|`-separated strings. Empty means none; read them through `conceptList`, `imageList`, and `sourceList`.
- `Notes.extractedText` is only set on notes from older builds. Nothing writes it now.
- `ChatEntries.role` is `'user'` or `'assistant'`. The column is plain text and the database does not enforce this.

Read helpers:

- `displayText` is `editedText ?? originalContent`. `originalContent` joins the trimmed typed text and extracted text with a blank line, omitting empty parts.
- `filePaths` lists every file the note owns: PDF, voice, and photos.

Schema and migrations:

- `beforeOpen` sets `PRAGMA foreign_keys = ON`. The cascades above depend on it.
- Drift does not wrap `onUpgrade` in a transaction, and `user_version` only moves after it returns. Every migration step must therefore be atomic and safe to re-run, so an interrupted upgrade can never leave the app unable to open. The existing steps use `transaction`, a `PRAGMA table_info` guard before adding a column, and `CREATE INDEX IF NOT EXISTS`.
- Schema snapshots for v1 to v4 live in `drift_schemas/` and `test/generated_migrations/`. `test/migration_test.dart` validates upgrades against them, including re-runs after an interruption.

## Side Effects

- Opens the on-device SQLite database named `fikra`, and sets the foreign-key pragma on every open.
- Upgrading from v1 rewrites `notes` rows: recordings move from the attachment columns to `voice_path`, and the attachment columns are cleared for those rows.
- Upgrading to v3 creates the six indexes.
- Upgrading to v4 adds the `image_paths` column.

## Verification

- Run: `flutter analyze && flutter test`
