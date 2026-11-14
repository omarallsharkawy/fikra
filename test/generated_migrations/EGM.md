# Generated migration databases

`schema.dart` dispatches v1–v7 generated schema fixtures; `schema_v5.dart` includes the attachment table, foreign key and index. Never edit generated Dart by hand. Regenerate with `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/` and run migration tests.

The generated dispatcher now includes v6. schema_v6.dart captures local groups, link metadata, unchanged NOT NULL labels and the appended Notes.groupId column, group foreign keys and indexes; all files are generated with the documented drift tooling.

The generated dispatcher includes v7; schema_v7.dart captures all eight transcription columns (including transcription_attempts, default 0) and their defaults/nullability. Generated using drift_dev, never hand-edited.
