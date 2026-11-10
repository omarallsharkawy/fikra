# Integration tests

`stress_test.dart` seeds the isolated stress database in batches, with six ordered attachments (two of each kind) on every fourth note, and times `watchProjectAttachments` as used by cards. No legacy attachment fields are written. It retains the existing scroll/search/graph/AI timing approach and never touches real user files. Run the profile drive command at the top of the file on `com.fikra.app.stress`; do not use the production install for migration experiments.

Stress link seed rows explicitly include v6 origin ai, dismissed false and createdAt; the UI and stress workload are unchanged.
