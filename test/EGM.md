# Tests

## Overview

Unit and widget tests for FIKRA. Run `flutter test`; screenshot-tagged tests are skipped by default. [support](support/EGM.md) owns the real-app harness; [screenshots](screenshots/EGM.md) owns design-review captures. Generated migration fixtures are not hand-edited.

## PDF coverage

- `app_flow_test.dart`: PDF-row route push through the real router, removal of the card overlay, PDF-icon taps opening the note, missing-file error and external opener path, ignored query-path input, notes without PDFs, deleted notes and unchanged external photo opening.
- `pdf_viewer_test.dart`: injected corrupt/password failures, throwing external opener, default missing-file preflight, native-document disposal after normal and late load completion. Test documents are lifecycle fakes; no PDFium rendering is required.
- Native rendering, zoom gestures, page-indicator tracking, and large-file responsiveness/memory require a device check.

## Verification

`dart format -l 120 lib test integration_test`, `flutter analyze`, `flutter test`, and `rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots`.

## Multi-attachment coverage

`multi_attachments_test.dart` tests populated v4→v5 migration, empty paths, partial and complete backfill re-runs, orphan sweeping, six-file order, mid-copy and database failures, atomic edits and deferred deletion, empty drafts, analysis preservation, whole-note/wipe cleanup and serialized voice playback. `attachment_flows_test.dart` exercises two PDF routes, unsaved/discard cleanup, the empty block, repeated PDF picking, attachment-only edits with an AI call counter, PDF titles without extensions and retained drafts after failures. Fixtures use real small temporary files; generated snapshots are produced by drift tooling.

## Phone follow-up regressions

`phone_regressions_test.dart` covers shared blank-title graph labels, zoom centre invariance in Arabic/English before and after height-only resizing, PDF taps during entry/return transitions, actual RTL size glyph ordering on Add/Edit/details, and full proposal labels with real fonts at 1–3× scaling. The old password/generic state, blank graph text, zoom drift and default English wrapping were reproduced before fixing them. Size and transition tests confirm the already-correct behavior without speculative production changes.

Password tests also verify no retry, preserved external opening, and disposal/classification of an encrypted document accepting an empty password. Large-text proposal tests use a details-only fixture to avoid the unrelated existing fixed-height tab-bar overflow under large system text.

## Attachment review regressions

`attachment_review_test.dart` saves actual Add-created drafts in both languages, verifies legacy auto-titles and safe retitling, title-independent empty validation, cached offstage Add preservation, double-tap Save exclusion, widget-level playback arbitration/lazy allocation/disposal, playback-stop-before-recording, cross-screen microphone ownership, disabled busy Cancel, and immediate temporary recording deletion without confirmation. `recording_lifecycle_test.dart` exercises permission, start, stop/cancel failures and disposal during pending permission/start/cancel using the actual AudioRecorder wrapper. `multi_attachments_test.dart` asserts postcommit non-I/O cleanup errors preserve committed copies, source recomputation preserves insights, and sweep grace protects an uncommitted file. The two-PDF flow records the path observed by the PDF loader fake.

## v6 local operations

`links_groups_moves_test.dart` covers multi-target links, reverse duplicates, suggestion/tombstone conversion, label normalization/empty-string persistence and surrogate-safe boundary caps, accept/dismiss/stale IDs, hidden dismissals, analysis protection and pre-cap filtering, linksOnly preservation, move impact/deletes/internal links/group clearing and actual file/sweep preservation, unknown destinations, serial relinking with failures/timeouts, every group rule, assignment, group/project deletion and wipe. `migration_test.dart` validates populated v4/v5→v6, preserved legacy reverse links/metadata, partial v6 state and full reruns against generated schema v6. Existing attachment migration tests also validate the current schema v6.

Review regressions cover distinct unordered move-impact pairs with user precedence, mid-analysis project moves in normal and linksOnly jobs, stale accepts of dismissed/tombstone/user rows, untouched updatedAt in linksOnly, UTF-16 surrogate boundaries for user/AI labels, ready-state relink failures/timeouts and reverse AI dismissal when removing user links. Migration tests also assert physical/declared Notes column order and the retained NOT NULL label constraint.
