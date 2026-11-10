# Note Details

## Overview

The pushed screens for one note: the read view at `/note/:id`, editor at `/note/:id/edit`, and local PDF viewer at `/note/:id/pdf/:attachmentId`, mounted by `lib/app/router.dart`. The read view shows content, the AI rewrite proposal, attachments (PDFs open in-app; photos open externally), concepts, and related notes.

## Interface

- `note_details_screen.dart`
  - `NoteDetailsScreen({required String noteId, Note? initial})`: `ConsumerStatefulWidget`. `initial` is the note the caller already has.
- `edit_note_screen.dart`
  - `EditNoteScreen({required String noteId})`: `ConsumerStatefulWidget`.
- Consumes `noteProvider`, `linksOfProjectProvider`, `notesOfProjectProvider`, `notesRepoProvider`, and `noteProcessorProvider` from `lib/app/providers.dart`, `noteTitle` and `sourceIcons` from [shared](../shared/EGM.md), and `VoicePlayer` from `lib/core/widgets/voice_player.dart`.

## Invariants

- `initial` is displayed only until `noteProvider` has a value or an error.
- Related notes are read with the note's own `projectId`, never the `selected*` providers, so the screen works when the note is outside the selected project.
- Related notes render only when the note's status is `ProcessingStatus.ready`, with one row per other note (the first matching link wins).
- The improved/original toggle appears only when `Note.hasImprovedVersion` is true.
- The proposal card appears only when `rewrite == RewriteStatus.pending` and `proposedText` is non-null. `_busy` locks its buttons during a decision.
- After a delete, the screen pops only if the delete succeeded. Delete requires `confirmDestructive`.
- `EditNoteScreen` creates its text controllers once, from the first non-null note, starting from `title` and `displayText`. Later stream emissions do not overwrite them.
- Once the controllers exist, leaving the screen goes through `_requestLeave`: unsaved edits prompt for save, discard, or stay. `_requestLeave` does nothing while `saving`.
- `_exit` sets `_allowPop` before popping on the next frame, bypassing the unsaved-changes guard.
- Field limits: title 80 characters, text 5000 characters.

## Side Effects

- Writes through `NotesRepository`: `edit`, `acceptRewrite`, `rejectRewrite`, `restoreOriginal`, and `delete`. `delete` also removes the note's files.
- `NotesRepository.edit` keeps the old title when the new one is blank, clears `editedText` when the text equals the original, and discards a pending proposal only when body text changes. Attachment-only saves preserve analysis.
- Re-queues analysis through `NoteProcessor.retry` for a failed note.
- Plays voice attachments through `VoicePlayer`; PDF rows push the viewer, while photos and the viewer’s explicit external action use `openAttachment`.
- Pushes `/note/<id>/edit` and `/note/<other id>` (the latter with `extra`), pops routes, and shows toasts.

## Localization

All detail/editor actions, states and accessibility labels use `context.l10n`, including topics and related notes. Original-text guidance is shared for every note source. Rewrite actions measure the localized labels at the current text scale. They share spare width in a row when both fit, otherwise stack in the same order. Both allow full wrapping and increased height at larger scales without changing fonts or wording. Date headers use `appClockProvider`.

## Verification

- Run: `flutter analyze && flutter test`
- `test/app_flow_test.dart` imports both screens directly.

## PDF viewer

- `PdfViewerScreen({required noteId, required attachmentId})` reads the live note and its attachment stream; no navigation-supplied path is accepted. Missing/deleted notes, notes without a PDF, and note-query failures use `pdfLoadFailed` in `LoadErrorView`.
- `pdf_document_provider.dart` exposes `PdfDocumentLoader`, `pdfDocumentLoaderProvider`, and auto-disposed `pdfDocumentProvider(path)`. Tests override the loader to avoid file I/O and native initialization. Automatic retries are disabled; ordinary failures retain explicit retry. Password failures use `pdfPasswordProtected`, omit retry, and retain the header’s open-elsewhere action.
- The default loader checks readability asynchronously without reading bytes, initializes pdfrx, then calls `PdfDocument.openFile` with progressive loading and no password prompt. Non-encrypted zero-page documents are rejected as unsupported. The provider rejects encrypted documents, including those accepting an empty password, with `PdfPasswordException` and disposes them. Loading errors stay in the provider’s error state.
- Riverpod owns each native document and releases it on leaving/changing the path, including late load completion after disposal. `PdfDocumentRefDirect(autoDispose: false)` prevents a second owner.
- pdfrx 2.12.0 supplies the default vertical continuous layout, pinch zoom, double-tap zoom, white document pages and lazy rendering. The PDF subtree is explicitly LTR; the header, error state and `pdfPageOf` indicator retain the app direction. No page color filter is applied.
- The rendering cache target is 32 MiB, with one viewport of vertical overscan and no horizontal overscan. This is a rendering-image budget, not a hard cap on total native memory. Selection is disabled; this feature does not index, upload, or analyze PDF text. PDF pages are exposed as a canvas with the localized page indicator outside the LTR subtree; pdfrx’s hardcoded English page semantics are excluded.
- Back and open-elsewhere use shared icon buttons. The latter remains enabled on document failures when a stored path exists, and is disabled when the note has no PDF path. Back falls back to `/notes` if there is no navigation history.
- `test/app_flow_test.dart` covers route/entry-point behavior; `test/pdf_viewer_test.dart` covers failures, opener exceptions, missing-file preflight and document lifetime without native rendering. Screenshot fixtures cover failure in both themes/locales; actual rendering and gestures require device verification.

## Large-file verification

Inspected pdfrx_engine 0.9.1: file opening uses `FPDF_LoadDocument` on `BackgroundWorker`, without `readAsBytes`; progressive loading initially loads one page. A standalone Linux PDFium smoke probe used a synthetic 200-page, 52,517,035-byte PDF with uncompressed page images: open 26 ms (one page initially loaded), first page rendered by 37 ms, last page by 90 ms; an asynchronous timer continued during the work. This validates the file-backed/progressive path, not Android frame times or total memory. Device stress verification remains required.

## Android compatibility

The regenerated release merged manifest retains minSdk 24 and targetSdk 36. Compared with the pre-feature manifest, no `uses-permission` entries were added or removed: `RECORD_AUDIO`, `ACCESS_NETWORK_STATE`, and the app’s existing dynamic-receiver permission remain. All three bundled Android PDFium binaries declare API 23 in their ELF Android identification notes, below the app’s unchanged minimum.

## Multiple files and edit drafts

Details uses `noteAttachmentsProvider` and renders every attachment in position order, grouping only consecutive photos into the existing grid. PDF row keys are `open-pdf-<attachmentId>` and push the new route. Photo keys retain their photo index. Only PDFs belonging to this note and matching the attachment ID can open; deleted attachments/notes keep the existing error and retry state. PDF sizes explicitly render LTR.

Edit initializes its file draft once from the attachment stream and shares `AttachmentEditing` with Add. File changes participate in the unsaved guard; saved-file removal requires the existing destructive dialog, then hides the draft entry. Temporary voices are removed and deleted immediately without confirmation. Save blocks no body text plus no files, regardless of title, copies new files first, commits text and attachments atomically, then deletes removed stored files and temporary recordings. Copy/database failure rolls back copies, leaves existing files/rows untouched and retains the draft with `changesSaveFailed`. Leaving discards all changes and cleans new temporary recordings. Attachment-only edits never request analysis; changed text retains the existing original/rewrite behavior. Save retitles an untouched file auto-title when its matching file was removed from a text-free draft, using the new first file and the shared localized helper; explicitly edited titles are kept. Cancel is disabled for recording, picking and saving. Edit never clears picker copies, preserving the offstage Add draft. Postcommit disk cleanup cannot roll back referenced copies.

## Phone regression checks

`phone_regressions_test.dart` checks PDF row taps during incoming and return-route transitions in both languages; no intermittent navigation cause was found and gesture/routing code is unchanged. File-size glyph-order tests cover Add, Edit and details; both render sites already explicitly use LTR. Proposal tests use real fonts at scales 1, 1.5, 2 and 3 and verify full rendered label height and unchanged text scaling. `pdf_viewer_test.dart` distinguishes password failures, verifies no retry and external opening, and tests disposal of encrypted documents accepting an empty password.
