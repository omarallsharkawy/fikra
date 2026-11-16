# Drift schema snapshots

Versioned schema JSON generated from `lib/data/local/database.dart`; do not hand-edit. v5 adds `note_attachments` and its noteId index while retaining all legacy columns.

Regenerate: `dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/`, then `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`. Verify with migration tests, including populated v4 upgrades and re-runs.

v6 adds link provenance/dismissal/time, unchanged NOT NULL labels (empty string for no reason), note_groups and indexed notes.group_id. Snapshot generation uses the same dump command; all earlier snapshots remain unchanged.

v7 adds attachment transcript, transcriptNoteText (redo/body deduplication marker), transcriptionStatus default none, failure, engine, completion time, persisted request order and transcriptionAttempts (default 0). The v7 snapshot is generated with drift_dev; earlier JSON snapshots remain unchanged.

## v8

Generated drift_schema_v8.json appends transcription_policy (off), nullable transcript_correction/corrected_at and transcript_revision (0). Earlier snapshots are unchanged. The migration fixture covers real populated v7, a partial v8 addition, and repeated upgrades preserving explicit off.
