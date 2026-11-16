# Add

The composer at `/add` saves typed text and any number of PDFs, recordings and photos locally. `AddScreen` retains the existing text fields, focus behavior and layout. `add_save.dart` snapshots the draft, calls `saveAttachmentDraft`, then queues current-text analysis only after commit. A file-only auto-title uses shared `attachmentTitle`: PDF basename without extension, localized voiceRecording for voice, or photosTitle for photos. The first draft file chooses the title; counts stay on the card with no suffix.

Picking, recording, previews, permission UI and the toolbar are extracted into [shared](../shared/EGM.md). `AttachmentEditing<AddScreen>` owns the attachment list and busy states. `inline_recorder.dart` remains a compatibility export of the shared public recorder widget and constants.

Saving is disabled while recording, picking or already saving; file actions and removal are locked during saving or recording. The mic and PDF buttons stay enabled after earlier files. Each recording has its own player/removal; consecutive photos share the existing strip. Copy/insert failure removes destination copies, keeps the draft and source recordings, and uses `noteSaveFailed`. Success cleans temporary recordings/cache copies, clears the draft and navigates to notes. Dispose cleans unsaved recordings, including a recording still starting or stopping.

Toolbar keys remain `add-mic`, `add-pdf`, `add-image`, `add-save`, `add-stop`, `add-cancel-rec`. Multiple previews use attachment identity/path keys. Fonts and composer motion tokens are unchanged; colours now use Pearl. PDF sizes render explicitly LTR in either locale.

Verification: `flutter analyze`, `flutter test`, screenshot suite. `attachment_flows_test.dart` covers repeated multi-PDF picking, retained drafts after failed saves and file-only titles; `multi_attachments_test.dart` covers six-file saves and rollback.

Phase 2 snapshots auto-transcription at save and combines it with per-new-voice draft toggles through transcriptionDraft. The attachment insert persists queued status atomically; after commit saved(noteId, newPaths) wakes the app-wide transcription queue without awaiting native work. Existing IDs are never re-queued. A failed wake-up uses trQueueFailed, leaves the saved note/files intact and is recovered at launch. When the save queued at least one recording, `askTranscriptionNotificationsOnce` (features/shared) runs unawaited after the saved toast and before navigating away; it never delays or fails the save.

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.

## Voice 2a

Save resolves only unresolved new-recording defaults; an explicit off chip overrides global auto. New requested voice paths alone wake the queue after commit. Saved IDs never produce save requests. Capture UI always exposes the off/after-save choice with the shared chips; no capture format or lifecycle change is made.

## Floating navigation (redesign phase 2)

Add is entered through nav-add, a floating gradient button; its StatefulShellBranch and draft lifecycle remain unchanged. The composer ListView adds NavigationInset.of(context) to its existing 24 dp bottom padding. The shell hides both floating controls while the keyboard is open and reduces the inset to zero.
