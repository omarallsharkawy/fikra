# Add

The composer at `/add` saves typed text and any number of PDFs, recordings and photos locally. `AddScreen` retains the existing text fields, focus behavior and layout. `add_save.dart` snapshots the draft, calls `saveAttachmentDraft`, then queues typed-text analysis only after commit. A file-only auto-title uses shared `attachmentTitle`: PDF basename without extension, localized voiceRecording for voice, or photosTitle for photos. The first draft file chooses the title; counts stay on the card with no suffix.

Picking, recording, previews, permission UI and the toolbar are extracted into [shared](../shared/EGM.md). `AttachmentEditing<AddScreen>` owns the attachment list and busy states. `inline_recorder.dart` remains a compatibility export of the shared public recorder widget and constants.

Saving is disabled while recording, picking or already saving; file actions and removal are locked during saving or recording. The mic and PDF buttons stay enabled after earlier files. Each recording has its own player/removal; consecutive photos share the existing strip. Copy/insert failure removes destination copies, keeps the draft and source recordings, and uses `noteSaveFailed`. Success cleans temporary recordings/cache copies, clears the draft and navigates to notes. Dispose cleans unsaved recordings, including a recording still starting or stopping.

Toolbar keys remain `add-mic`, `add-pdf`, `add-image`, `add-save`, `add-stop`, `add-cancel-rec`. Multiple previews use attachment identity/path keys. Existing colors, fonts, motion tokens and tab order are unchanged. PDF sizes render explicitly LTR in either locale.

Verification: `flutter analyze`, `flutter test`, screenshot suite. `attachment_flows_test.dart` covers repeated multi-PDF picking, retained drafts after failed saves and file-only titles; `multi_attachments_test.dart` covers six-file saves and rollback.
