# Device draft persistence

Draft text, optional-title visibility and selected local tag IDs are stored under
the existing encrypted, origin/account-scoped UI record, separately for each
project. Edits debounce for 350ms; closing Capture, backgrounding and account
changes flush a captured snapshot. There is no note creation or AI work until
explicit Save. A write failure keeps the current draft and exposes a localized
retry; immediate process termination before a successful write may lose recent
keystrokes. No cross-device draft synchronization is implied.

Confirmed creation removes the durable draft and assigns selected local tags.
The original write-ahead idempotency attempt is retained until local cleanup
succeeds too, so retry after a storage failure reconciles the same remote note.
Store updates preserve unrelated profile/category/undo fields. Account changes
invalidate late callbacks, and project changes discard the previous capture's
recording/transcript without moving it into the new project.

Verification: `test/product/draft_autosave_test.dart` covers restart, account and
project isolation, failed writes/retry, confirmed cleanup, tag assignment,
idempotent reconciliation and late transcription cancellation. Existing native
recorder and confirmed-save lifecycle tests remain required.
