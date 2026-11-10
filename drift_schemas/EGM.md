# Drift schema snapshots

Versioned schema JSON generated from `lib/data/local/database.dart`; do not hand-edit. v5 adds `note_attachments` and its noteId index while retaining all legacy columns.

Regenerate: `dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/`, then `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`. Verify with migration tests, including populated v4 upgrades and re-runs.
