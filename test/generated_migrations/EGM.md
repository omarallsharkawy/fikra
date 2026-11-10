# Generated migration databases

`schema.dart` dispatches v1–v5 generated schema fixtures; `schema_v5.dart` includes the attachment table, foreign key and index. Never edit generated Dart by hand. Regenerate with `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/` and run migration tests.
