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
  - `schemaVersion` is 8.
- `extension NoteX on Note`: `conceptList`, `originalContent`, `displayText`, `hasImprovedVersion`.
- `extension ChatEntryX on ChatEntry`: `sourceList`, `isUser`.

Tables (Drift data class in parentheses):

| SQL table      | Drift class             | Primary key | Foreign keys (`CASCADE` unless stated)                        |
| -------------- | ----------------------- | ----------- | ------------------------------------------------------------- |
| `projects`     | `Projects` (`Project`)  | `id`        | None                                                          |
| `notes`        | `Notes` (`Note`)        | `id`        | `project_id` to `projects`; `group_id` to groups (`SET NULL`) |
| `note_groups` | `NoteGroups` (`NoteGroup`) | `id` | `project_id` to `projects`; `parent_id` to groups (`SET NULL`) |
| `note_attachments` | `NoteAttachments` (`NoteAttachment`) | `id` | `note_id` to `notes` |
| `note_links`   | `NoteLinks` (`NoteLink`) | `id`       | `project_id` to `projects`; `source_id`, `target_id` to `notes` |
| `chat_entries` | `ChatEntries` (`ChatEntry`) | `id`    | `project_id` to `projects`                                    |
| `settings`     | `Settings` (`Setting`)  | `key`       | None                                                          |

Indexes: `notes_project_created`, `notes_status`, `note_links_project`,
`note_links_source`, `note_links_target`, `chat_entries_project_created`, `note_attachments_note`.

## Invariants

Column semantics:

- `Notes.originalText` keeps typed text plus recording transcripts; only explicit, revision-checked transcript corrections can safely replace their copied paragraph.
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
- Schema snapshots for v1 to v7 live in `drift_schemas/` and `test/generated_migrations/`. `test/migration_test.dart` validates upgrades against them, including re-runs after an interruption.

## Side Effects

- Opens the on-device SQLite database named `fikra`, and sets the foreign-key pragma on every open.
- Upgrading from v1 rewrites `notes` rows: recordings move from the attachment columns to `voice_path`, and the attachment columns are cleared for those rows.
- Upgrading to v3 creates the six indexes.
- Upgrading to v4 adds the `image_paths` column.

## Verification

- Run: `flutter analyze && flutter test`

## v5 backfill

One transaction guards table creation, creates the note index with IF NOT EXISTS, and copies nonblank legacy PDF, voice and photo paths. Order is PDF, voice, then photos in their original order. IDs are deterministic (`legacy:<note id>:pdf`, `voice`, `image:<original index>`), and inserts ignore an existing primary key, so partial or complete repeated backfills create no duplicates. Metadata and note creation time are retained; legacy columns are never cleared. Tests cover empty paths, partial backfill, a complete re-run and the orphan sweep.

## v6 migration and API

`schemaVersion` is 8. `LinkOrigin { ai, user }` describes link provenance; links also have dismissed (false by default) and nullable createdAt. Labels remain NOT NULL, as in v5; no reason is represented by `''`. Existing label values are preserved without rebuilding the link table.

`NoteGroups` (`NoteGroup`) has id, projectId (cascade), parentId (self FK, set null), name, nullable color, position and createdAt; project and parent indexes support lookup. `Notes.groupId` is nullable, indexed and references groups with set null. New installs create the group table before notes. groupId is declared after all legacy Notes columns so fresh and upgraded column order matches.

The v6 transaction guards group creation via sqlite_master, guards group_id and each new link column via table_info. The existing link table is not rebuilt and its label constraint is unchanged. It creates all three new indexes with IF NOT EXISTS. No row or file is lost and repeating the step preserves existing group assignments and link metadata.

The v5 backfill now explicitly selects only legacy attachment columns, never the generated current Notes model. This avoids asking a populated v4 database for group_id before v6 creates it. v2 SQL, v3 named indexes and v4's guarded individual column do not read future models and are unchanged. Snapshots cover v1–v6, with populated v4/v5 upgrades, partial v6 state and repeated v6 execution tested.

## v7 recording transcripts

NoteAttachments adds nullable transcript, transcriptNoteText, transcriptionFailure, transcriptionEngine and transcribedAt, plus nullable integer transcriptionOrder; transcriptionStatus is a text enum (none/queued/running/done/failed), NOT NULL default none. transcriptNoteText is the last text represented in the note body, retained when redo changes transcript so repeated redos never add a second paragraph while the old one remains. Engine IDs are provider-neutral strings; local IDs use local:ggml-<model>.bin. Failure codes are modelMissing/busy/audioUnreadable/other. transcribedAt records the last completion, including failure; an older successful transcript and its engine remain visible during failed redo.

One transaction guards each v7 column with PRAGMA table_info. The v5 legacy backfill now inserts only historical columns with raw SQL, avoiding current generated fields before v7 exists on an interrupted v5 database. Snapshots and generated fixtures include v7; real populated v6, partial v7, repeated v7 and every earlier upgrade are tested. database.g.dart is regenerated with build_runner, not hand-edited.

transcription_order.dart allocates MAX(transcription_order)+1 inside the caller transaction. New save requests and manual enqueues persist this order; recovery retains it for interrupted jobs. No audio data is stored in SQLite.

Schema v7 also adds `note_attachments.transcription_attempts` (INTEGER NOT NULL DEFAULT 0). It is in the same idempotent v7 step: each column is added only if `PRAGMA table_info` lacks it, so a partial or repeated upgrade keeps existing counts.

## v8 recording choices and transcript corrections

Schema v8 appends transcription_policy (TEXT NOT NULL, off), transcript_correction (nullable TEXT), corrected_at (nullable timestamp) and transcript_revision (INTEGER NOT NULL, 0). TranscriptionPolicy is off / afterSave / live; live is reserved and not offered. The guarded transaction backfills old voice rows with any non-none status to afterSave, otherwise off. Backfill only runs when the policy column is newly added, so re-running preserves later explicit off choices. Partial column additions and every earlier upgrade remain supported. v8 JSON/fixture and the dispatcher are generated with the same drift commands as v7.

transcript remains machine output; display uses correction ?? transcript. transcriptNoteText is the exact copied block used for safe correction updates. Revision is an opaque increasing conflict token; its low bit means newer machine output is waiting while a correction exists. Correction/restore clears that bit; redo retains the correction and sets it. This avoids a timestamp race within SQLite's second resolution, without another schema column.
