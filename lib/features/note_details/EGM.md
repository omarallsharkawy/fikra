# Note Details

## Overview

The pushed screens for one note: the read view at `/note/:id`, editor at `/note/:id/edit`, and local PDF viewer at `/note/:id/pdf`, mounted by `lib/app/router.dart`. The read view shows content, the AI rewrite proposal, attachments (PDFs open in-app; photos open externally), concepts, and related notes.

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
- Once the controllers exist, leaving the screen goes through `_requestLeave`: unsaved edits prompt for save, discard, or stay. `_requestLeave` does nothing while `_saving`.
- `_exit` sets `_allowPop` before popping on the next frame, bypassing the unsaved-changes guard.
- Field limits: title 80 characters, text 5000 characters.

## Side Effects

- Writes through `NotesRepository`: `edit`, `acceptRewrite`, `rejectRewrite`, `restoreOriginal`, and `delete`. `delete` also removes the note's files.
- `NotesRepository.edit` keeps the old title when the new one is blank, clears `editedText` when the text equals the original, and discards any pending rewrite proposal.
- Re-queues analysis through `NoteProcessor.retry` for a failed note.
- Plays voice attachments through `VoicePlayer`; PDF rows push the viewer, while photos and the viewer’s explicit external action use `openAttachment`.
- Pushes `/note/<id>/edit` and `/note/<other id>` (the latter with `extra`), pops routes, and shows toasts.

## Localization

All detail/editor actions, states and accessibility labels use `context.l10n`, including topics and related notes. Original-text guidance is shared for every note source. Rewrite buttons retain their existing placement and height with smaller inner padding and up to two lines for the keep-original label to fit approved copy. Date headers use `appClockProvider`.

## Verification

- Run: `flutter analyze && flutter test`
- `test/app_flow_test.dart` imports both screens directly.

## PDF viewer

- `PdfViewerScreen({required noteId})` reads the live note; no navigation-supplied path is accepted. Missing/deleted notes, notes without a PDF, and note-query failures use `pdfLoadFailed` in `LoadErrorView`.
- `pdf_document_provider.dart` exposes `PdfDocumentLoader`, `pdfDocumentLoaderProvider`, and auto-disposed `pdfDocumentProvider(path)`. Tests override the loader to avoid file I/O and native initialization. Automatic retries are disabled; the existing retry action explicitly reloads.
- The default loader checks readability asynchronously without reading bytes, initializes pdfrx, then calls `PdfDocument.openFile` with progressive loading and no password prompt. Encrypted (including empty-password) and zero-page documents are rejected. Loading errors stay in the provider’s error state.
- Riverpod owns each native document and releases it on leaving/changing the path, including late load completion after disposal. `PdfDocumentRefDirect(autoDispose: false)` prevents a second owner.
- pdfrx 2.12.0 supplies the default vertical continuous layout, pinch zoom, double-tap zoom, white document pages and lazy rendering. The PDF subtree is explicitly LTR; the header, error state and `pdfPageOf` indicator retain the app direction. No page color filter is applied.
- The rendering cache target is 32 MiB, with one viewport of vertical overscan and no horizontal overscan. This is a rendering-image budget, not a hard cap on total native memory. Selection is disabled; this feature does not index, upload, or analyze PDF text. PDF pages are exposed as a canvas with the localized page indicator outside the LTR subtree; pdfrx’s hardcoded English page semantics are excluded.
- Back and open-elsewhere use shared icon buttons. The latter remains enabled on document failures when a stored path exists, and is disabled when the note has no PDF path. Back falls back to `/notes` if there is no navigation history.
- `test/app_flow_test.dart` covers route/entry-point behavior; `test/pdf_viewer_test.dart` covers failures, opener exceptions, missing-file preflight and document lifetime without native rendering. Screenshot fixtures cover failure in both themes/locales; actual rendering and gestures require device verification.

## Large-file verification

Inspected pdfrx_engine 0.9.1: file opening uses `FPDF_LoadDocument` on `BackgroundWorker`, without `readAsBytes`; progressive loading initially loads one page. A standalone Linux PDFium smoke probe used a synthetic 200-page, 52,517,035-byte PDF with uncompressed page images: open 26 ms (one page initially loaded), first page rendered by 37 ms, last page by 90 ms; an asynchronous timer continued during the work. This validates the file-backed/progressive path, not Android frame times or total memory. Device stress verification remains required.

## Android compatibility

The regenerated release merged manifest retains minSdk 24 and targetSdk 36. Compared with the pre-feature manifest, no `uses-permission` entries were added or removed: `RECORD_AUDIO`, `ACCESS_NETWORK_STATE`, and the app’s existing dynamic-receiver permission remain. All three bundled Android PDFium binaries declare API 23 in their ELF Android identification notes, below the app’s unchanged minimum.
