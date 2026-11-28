# Note detail, review and reversible actions

The detail page now follows the supplied HTML header, 24px heading, 17px body,
metadata, category pills, purple suggestion card, Before/After/Changes segments,
related-note cards, action sheet and confirmation sheet in both languages and
themes. Displayed content, timestamps, processing state, proposals and references
come from the current repository. The approved floating navigation remains a
separate owner-approved deviation on shell pages.

Changes are computed from the real old/proposed strings using Unicode word,
whitespace and punctuation tokens. A bounded LCS preserves both full strings;
large unrelated regions become contiguous replacement spans rather than
allocating an unbounded matrix. The HTML's manually authored change boundaries
are examples, so real boundaries can differ. Flutter selection uses inline
background spans rather than the browser's rounded inline boxes. Native glyph
rasterization also differs from browser screenshots.

Apply and Delete first persist a five-second deferred operation in the encrypted
account/origin UI record. Undo cancels that record before the existing server
mutation. Pending deletion hides the note locally; pending acceptance shows the
actual proposal optimistically. The queue resumes on account restoration and
application resume, preserves multiple operations, and never transfers between
accounts. An uncertain response is reconciled against a fresh server read before
retry. Newer content, revision or proposal generation blocks an old operation.
Errors remain localized and expose retry/dismiss controls. Re-reading before
DELETE is best effort because the existing endpoint has no atomic revision
precondition; this remaining race is recorded in `BACKEND_REQUESTS.md`.

If persisting a cancellation fails, its Retry action retries cancellation rather
than committing the original mutation, even after the displayed window expires
while this process is running. Pending operations remain blocked until storage
recovers. Dismissal of an uncommitted blocked operation cancels it, and dismissing
a failed operation refreshes the visible note from the repository. A storage
failure never produces a successful Undo message.

The note menu keeps existing editing and reprocessing. Pin calls the deployed
PUT `/v1/notes/{id}/favorite` with an explicit desired boolean and account-bound
selection guards. Categories are device-only assignments, never backend concepts.
Android sharing generates a PNG from the real note and opens the system chooser
through a nonexported FileProvider restricted to the private share cache. Long
image bodies visibly truncate; this is not a full-content export. Platforms with
no implemented sharing adapter hide that menu item. No data is shared until the
owner chooses a destination in the system chooser.

Related references have no returned score or explanation. The page hides the
prototype's decorative score bars, displays only an actual shared category when
available, and hides the unsupported short-note classification. No prototype
notes, diff HTML, AI guidance or scores become production fallback data.

## Verification

- `flutter test test/product/word_diff_test.dart test/product/note_undo_test.dart`
  checks reconstruction, Unicode, bounded work, persisted Undo, account isolation,
  uncertain responses and edit conflicts.
- `flutter test test/product/redesign_note_test.dart` exercises Before/After,
  word changes, Apply/Undo, Delete/Undo, pin/unpin, category creation/assignment,
  PNG encoding and the native share channel in Arabic and English.
- `flutter test test/product/api_integration_test.dart` verifies the existing
  favorite endpoint/method/body as well as current integration contracts.
- Screenshot captures under `build/validation/redesign/{reference,after}/` compare
  the same 398×650 viewport in AR/EN and light/dark. These render the real Flutter
  widget tree with test-only injected repository records, not owner data or
  physical-device screenshots. The four-mode comparison is
  `build/validation/redesign/note-detail-comparison.png`.

The detail renderer now has 44dp interaction targets, respects reduced motion,
and provides loading, unavailable and typed error states. Root navigator sheets
keep their controls above the floating bar. Native build and physical installation
are verified separately from widget screenshots.
