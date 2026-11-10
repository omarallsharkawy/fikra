# Generated migration databases

`schema.dart` dispatches v1–v6 generated schema fixtures; `schema_v5.dart` includes the attachment table, foreign key and index. Never edit generated Dart by hand. Regenerate with `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/` and run migration tests.

The generated dispatcher now includes v6. schema_v6.dart captures local groups, link metadata, unchanged NOT NULL labels and the appended Notes.groupId column, group foreign keys and indexes; all files are generated with the documented drift tooling.
