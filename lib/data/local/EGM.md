# Local Database

## Overview

The Drift/SQLite schema for the offline app: tables, enums, the migration path
and the `Note` and `ChatEntry` read helpers. All persistence in
[`../EGM.md`](../EGM.md) goes through `FikraDatabase`.

`database.g.dart` is generated from `database.dart`. Do not edit it by hand;
regenerate it with `dart run build_runner build -d`.

## Interface

From `database.dart`:

- Enums: `NoteSource { text, voice, pdf }`, `ProcessingStatus { processing, ready, failed }`, `RewriteStatus { none, pending, accepted, rejected }`, `AttachmentKind { pdf, voice, image }`.
- `class FikraDatabase`
  - `FikraDatabase([QueryExecutor? executor])`: defaults to `driftDatabase(name: 'fikra')`; tests inject an executor.
  - `schemaVersion` is 5.
- `extension NoteX on Note`: `conceptList`, `originalContent`, `displayText`, `hasImprovedVersion`.
- `extension ChatEntryX on ChatEntry`: `sourceList`, `isUser`.

Tables (Drift data class in parentheses):

| SQL table      | Drift class             | Primary key | Foreign keys (all `ON DELETE CASCADE`)                        |
| -------------- | ----------------------- | ----------- | ------------------------------------------------------------- |
| `projects`     | `Projects` (`Project`)  | `id`        | None                                                          |
| `notes`        | `Notes` (`Note`)        | `id`        | `project_id` to `projects`                                    |
| `note_attachments` | `NoteAttachments` (`NoteAttachment`) | `id` | `note_id` to `notes` |
| `note_links`   | `NoteLinks` (`NoteLink`) | `id`       | `project_id` to `projects`; `source_id`, `target_id` to `notes` |
| `chat_entries` | `ChatEntries` (`ChatEntry`) | `id`    | `project_id` to `projects`                                    |
| `settings`     | `Settings` (`Setting`)  | `key`       | None                                                          |

Indexes: `notes_project_created`, `notes_status`, `note_links_project`,
`note_links_source`, `note_links_target`, `chat_entries_project_created`, `note_attachments_note`.

## Invariants

Column semantics:

- `Notes.originalText` is exactly what the user typed and is never overwritten.
- `Notes.editedText` is the version shown when set: an accepted AI rewrite or a user edit. `Notes.proposedText` is an AI rewrite awaiting accept or reject.
- `Notes.source` names the main content: `pdf` when a PDF is attached (a voice memo may sit beside it), `voice` for a recording alone, otherwise `text`.
- `NoteAttachments` owns all live files, with kind, path, optional name/bytes/duration, position and createdAt. Position preserves the draft order; `noteId` is indexed and cascades on note deletion.
- The old attachment columns remain solely for migration/recovery. New inserts omit them. No screen or normal attachment API reads them.
- `Notes.concepts` and `ChatEntries.sourceIds` are `|`-separated strings. Legacy `imagePaths` is only split during migration/recovery.
- `Notes.extractedText` is only set on notes from older builds. Nothing writes it now.
- `ChatEntries.role` is `'user'` or `'assistant'`. The column is plain text and the database does not enforce this.

Read helpers:

- `displayText` is `editedText ?? originalContent`. `originalContent` joins the trimmed typed text and extracted text with a blank line, omitting empty parts.
- Live file paths come from repository queries against `note_attachments`.

Schema and migrations:

- `beforeOpen` sets `PRAGMA foreign_keys = ON`. The cascades above depend on it.
- Drift does not wrap `onUpgrade` in a transaction, and `user_version` only moves after it returns. Every migration step must therefore be atomic and safe to re-run, so an interrupted upgrade can never leave the app unable to open. The existing steps use `transaction`, a `PRAGMA table_info` guard before adding a column, and `CREATE INDEX IF NOT EXISTS`.
- Schema snapshots for v1 to v5 live in `drift_schemas/` and `test/generated_migrations/`. `test/migration_test.dart` validates upgrades against them, including re-runs after an interruption.

## Side Effects

- Opens the on-device SQLite database named `fikra`, and sets the foreign-key pragma on every open.
- Upgrading from v1 rewrites `notes` rows: recordings move from the attachment columns to `voice_path`, and the attachment columns are cleared for those rows.
- Upgrading to v3 creates the six indexes.
- Upgrading to v4 adds the `image_paths` column.

## Verification

- Run: `flutter analyze && flutter test`

## v5 backfill

One transaction guards table creation, creates the note index with IF NOT EXISTS, and copies nonblank legacy PDF, voice and photo paths. Order is PDF, voice, then photos in their original order. IDs are deterministic (`legacy:<note id>:pdf`, `voice`, `image:<original index>`), and inserts ignore an existing primary key, so partial or complete repeated backfills create no duplicates. Metadata and note creation time are retained; legacy columns are never cleared. Tests cover empty paths, partial backfill, a complete re-run and the orphan sweep.
