# Note Details

## Overview

The pushed screens for one note: the read view at `/note/:id`, editor at `/note/:id/edit`, and local PDF viewer at `/note/:id/pdf/:attachmentId`, mounted by `lib/app/router.dart`. The read view shows content, the AI rewrite proposal, attachments (PDFs open in-app; photos open externally), topics, and the links section.

## Interface

- `note_details_screen.dart`
  - `NoteDetailsScreen({required String noteId, Note? initial})`: `ConsumerStatefulWidget`. `initial` is the note the caller already has.
- `edit_note_screen.dart`
  - `EditNoteScreen({required String noteId})`: `ConsumerStatefulWidget`.
- Consumes `noteProvider`, `linksOfProjectProvider`, `notesOfProjectProvider`, `notesRepoProvider`, `linksRepoProvider`, and `noteProcessorProvider` from `lib/app/providers.dart`, `noteTitle` and `sourceIcons` from [shared](../shared/EGM.md), and `VoicePlayer` from `lib/core/widgets/voice_player.dart`.

## Invariants

- `initial` is displayed only until `noteProvider` has a value or an error.
- Links are read with the note's own `projectId`, never the `selected*` providers, so the screen works when the note is outside the selected project.
- The links section renders for every status, with one row per other note (`linksOfNote`: the user row wins, otherwise the first suggestion).
- The improved/original toggle appears only when `Note.hasImprovedVersion` is true.
- The proposal card appears only when `rewrite == RewriteStatus.pending` and `proposedText` is non-null. `_busy` locks its buttons during a decision.
- After a delete, the screen pops only if the delete succeeded. Delete requires `confirmDestructive`.
- `EditNoteScreen` creates its text controllers once, when note and attachment snapshots are available, starting from `title` and `displayText`. Later stream emissions do not overwrite them.
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

## Links section (links phase 2)

`note_details_screen.dart` is a library split into parts, each under 300 lines: `note_details_body.dart` (`_Body`, `_ProcessingCard`), `note_details_cards.dart` (`_ProposalCard`, `_Attachment`, `_Photos`), `note_links_section.dart` (`_NoteLinks`), `note_link_row.dart` (`_LinkRow`, `_InlineAction`, `_DashedOutline`); shared `note_link_actions.dart` now owns `showLinkOptions` and the private reason editor. Everything outside the links section is moved unchanged.

- Header `noteLinksHeader`, then the "Link to a note" secondary button (key `link-to-note`, always shown), then the empty text, the load failure or the rows inside a `FikraSwitcher`.
- Your link: solid glass card, accent link icon, reason in `textLink`, options control (`link-options-<otherId>`). Suggestion: no fill, dashed `borderGraph` outline, sparkle icon in `textMeta`, outlined "Suggested" tag, inline accept (`link-accept-<otherId>`, primary pill) and reject (`link-reject-<otherId>`, secondary pill). The open area is `open-link-<otherId>`; row key `note-link-<otherId>`.
- Options sheet: edit reason (closes, then opens `_LinkReasonSheet` from the page if it is still mounted) and remove (`confirmDestructive` with `removeLinkConfirm`, then `removeLink` and the `linkRemoved` toast). Reject has no confirmation. Accept and reject call shared project-bound pair commands with the two note ids and the rendered link project, so they still work after a re-analysis replaced the suggestion. The options sheet builds its content from its own context, and `_options` captures the repository and link id before opening it; the confirmed removal runs with the sheet's context and only touches `_busy`/`setState` when the section is still mounted, so a page disposed under the sheet (note deleted) is never used.
- Guards: `_busy` holds unordered note-pair keys (`_pairKey`) with an accept, reject or remove in flight; `_away` blocks a second open/sheet tap until the pushed route or sheet closes (also in the same frame, before go_router pushes). Failures use `runAction` with `linkUpdateFailed`. `_LinkReasonSheet` just closes for a link removed meanwhile (`updateLabel` is a no-op then); failures show an inline error banner and keep the sheet. It pops only if its route is still current, so dismissing it while saving never closes the page.
- All controls are 48 dp targets with semantics labels (the open area has a 48 dp minimum height, which matters for a suggestion without a reason); insets are directional. No new colours or motion: sheets and the switcher use the existing reduced-motion handling.
- Verification: `test/note_links_test.dart`; screenshots `28`–`34` in `test/screenshots/screens_test.dart`.

## Move to another project (links phase 3)

- The options sheet shows "Move to another project" (key `note-move`) only when another project exists, like "restore original" is shown only when it applies (hidden, not disabled). The choice is read from `projectsProvider` when the sheet opens.
- `_move` closes the options sheet first, then opens `showProjectPicker` (shared) from the page; the note's own project isn't offered. After a pick it reads `NotesRepository.moveImpact` and shows `confirmDestructive` with `moveNoteTitle(Fmt.isolate(project))` and `moveNoteMessage` (public, `@visibleForTesting`): the plain `moveNoteBodyNoLinks`, or `moveNoteBody` with the non-zero counts (`Fmt.links` for your links, `Fmt.suggestions`) joined by `Fmt.list`. The confirm is red only when something will be removed.
- On confirm: `moveNotes` through `runAction` (`moveNoteFailed`); then `NoteProcessor.relink` for the moved ids, not awaited; the `noteMoved(Fmt.isolate(project))` toast; `context.go('/notes')` only if this page's route is still current (captured before the confirm), so the page closes to the notes list whichever tab opened it, while a page opened on top during a slow save (another note, the editor) is left alone.
- After confirm, `moveImpact` is read again; if the numbers changed while the dialog was open (an analysis added suggestions), the dialog is shown again with the new numbers instead of moving. The selected project is not changed.
- Failure (target project deleted meanwhile included) changes nothing and keeps the page. A note deleted meanwhile moves nothing (empty result): no toast, the page already shows "Note not found".
- `_moving` covers the whole flow from picker to result, so a second move can't start while one is saving, and `_showOptions` returns early while it is set: the options sheet (and so Edit) stays shut until the move ends, so no edit can be opened and then discarded by the move's navigation. Same-frame double taps on the option, a project row or the confirm never reach a popped route (the Navigator absorbs pointers after a pop), so they need no extra guard; `test/project_moves_test.dart` checks the outcome.
- Verification: `test/project_moves_test.dart`; screenshots `35`–`38` in `test/screenshots/projects_test.dart`.

## Shared link actions (links phase 4)

The former `note_link_actions.dart` part moved to `features/shared/note_link_actions.dart`. Details imports `showLinkOptions` without changing its user-link appearance, callbacks, keys, confirmation or editor lifecycle. Inline suggestion actions call shared `changeSuggestedPair` inside the existing per-pair busy guard, so accept/reject show the shared toast with Undo; Undo brings the suggestion row back with its actions on. The graph uses those same sheets and pair operations. Existing `test/note_links_test.dart` remains the note-page regression suite.

## Shared move confirmation (links phase 5a)

`_move` now calls `confirmMove` from `shared/move_confirm.dart` (the same re-ask loop and danger flag, moved out unchanged). `moveNoteMessage(l10n, impact)` keeps its name and delegates to `moveMessage`. Behaviour, strings and keys are unchanged; `test/project_moves_test.dart` still covers them.

## Saved recording transcripts (phase 2)

VoiceTranscript renders below each existing VoicePlayer from attachment streams. It shows queued/running badges, the last successful transcript collapsed to three lines with expansion/RTL/selectable full text, and the producing engine (localized local model, or a provider-neutral ID fallback). Failed redos retain the old transcript. Stable failure codes select plain messages and retry; modelMissing additionally opens /settings/voice-text. Manual transcribe/redo enqueues an attachment ID and returns immediately, with a local duplicate-tap guard and visible toast on persistence failure. No inference or model choice occurs inside this widget.

Edit combines the current auto preference with explicit new-voice toggles and persists queued requests with the note save; existing recordings retain transcript/status/provenance and are never automatically re-queued. The queue wakes only after successful commit. Later transcription success re-reads live note text, preserving user edits made during native work.

A transcript counts as text the user wrote: it is in originalText (and editedText when edited), so «ارجع للأصل» keeps it and an unedited voice note offers no restore. Edit loads its text once. Edit passes its base note/attachment snapshot and raw draft to the repository. After copies finish, the edit transaction reconciles the live body using attachment IDs, revisions and copied-block markers. It preserves typed edits, prior corrections and explicit removals; competing replacements raise NoteEditConflict. Conflict rollback removes new copies and keeps the editor draft. Edit save and the details transcribe/retry/redo button call `askTranscriptionNotificationsOnce` (features/shared) unawaited when they queue a recording.

`interruptedTwice` failures show `trInterruptedTwice` and offer both retry and voice settings (a smaller model is one way out). The details button's transcribe/retry/redo is a manual request, so it resets the attempt count.

Phase 3 TranscriptionSource renders remote:<serviceId> as the localized Via <name>, retaining attribution after config/key deletion through the alias archive. Stable remote failure codes show plain localized offline/auth/quota/size/service/response/timeout/consent messages. Failed recordings offer both retry and voice settings; existing manual enqueue/crash-attempt reset and local transcript behavior remain unchanged. No key or provider request body reaches details.

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.
Graph-related note rows, rewrite/read cards, transcripts, edit areas and the PDF page counter remain solid reading surfaces.

## Voice 2a transcript editing

VoiceTranscript displays correction ?? machine transcript, retaining machine source attribution. TranscriptActions opens /note/:id/transcript/:attachmentId (MaterialPage), and shows New transcript available / Use it after a redo while correction is retained. Use calls the same revision-checked correction service with null correction; unsafe note copies show an append action.

TranscriptEditorScreen initializes its long text controller once, automatically chooses RTL/LTR, and uses existing Glass/TextField/buttons/banners/sheets. Save/cancel and the existing save/discard/stay guard protect unsaved edits. Restore machine transcript clears correction. A conflict keeps the draft with a plain reopen message. A safe save that changes the note schedules the processor without awaiting it (an identical body is not rewritten); unsafe replacement keeps the editor and offers explicit append. Machine text is never overwritten by editing. All actions use stable keys; no text/correction is logged.

Edit's policy-only changes participate in the dirty guard. Attachment replacement preserves current transcription metadata from the live row; only explicit chip changes override live policy. Reopening an old recording never auto-queues it.

## Ordering & IA (redesign phase 4)

`NoteDetailsScreen` exposes a visible `note-edit` pill button (`SolidSurface` + `Icons.edit_outlined` + `edit` label, >= 48×48 dp target, `edit` semantics) in the top header row beside `options`, pushing `/note/<id>/edit` directly without opening the options sheet. While `_moving` is true, `note-edit` dims to 0.4 opacity and ignores taps alongside `options`. `_openingEdit` guards it from the tap until the editor closes, so a double tap opens one editor. The `Edit` row in `options` remains as a secondary path.

## Finishing (redesign phase 8)

`note_details_body.dart` marks the note title and `topicsHeader` with `Semantics(header: true)`; `edit_note_screen.dart` marks `editNote` with `Semantics(header: true)`; `_InlineAction` (`note_link_row.dart`) uses `minHeight: 36` + `Flexible` label so large text grows cleanly without overflowing.

Cold `/note/:id` renders `NoteDetailsPlaceholder` inside the existing opaque Pearl scaffold until the note arrives. Initial-note validation, live-data authority and Edit behavior are unchanged.
