# Add

## Overview

The composer tab, mounted at `/add` by `lib/app/router.dart`. It builds one note from typed text plus any of one voice recording, one PDF, and photos. The note is saved first, then queued for AI analysis of its typed text. Attachments stay on the device.

## Interface

- `add_screen.dart`
  - `AddScreen`: `ConsumerStatefulWidget` with no parameters.
  - Library file. Holds the imports, the `_Mic` and `_Rec` enums, and `_AddScreenState`: draft fields, `_canSave`, lifecycle and `build` (composer card, attachment switchers, mic card slot, footer note). Everything else is in the `part` files below, which see its private members.
- `add_voice.dart` (part): `extension _AddVoice on _AddScreenState` with `_startRecording`, `_teardown`, `_stopRecording`, `_cancelRecording`, `_discardVoice`.
- `add_files.dart` (part): `extension _AddFiles on _AddScreenState` with `_pickPdf`, `_removePdf`, `_pickImages`, `_removeImage`.
- `add_save.dart` (part): `extension _AddSave on _AddScreenState` with `_save` and `_fileOnlyTitle`.
- `add_toolbar.dart` (part): `_Toolbar`, the composer's bottom row, plus `_ToolButton` and `_RoundAction`.
  - Toolbar widget keys: `ValueKey('add-mic')`, `ValueKey('add-pdf')`, `ValueKey('add-image')`, `ValueKey('add-save')`, `ValueKey('add-stop')`, `ValueKey('add-cancel-rec')`.
- `attachment_chips.dart` (part): `_PdfChip` (name, size, remove) and `_ImageStrip` (photo thumbnails with remove buttons).
- `mic_permission_card.dart` (part): `_MicPermissionCard`, shown when the microphone permission is denied or blocked.
- `inline_recorder.dart`
  - `kWaveformSamples`: number of level samples drawn (48).
  - `kWaveformFloorDb`: dBFS floor for a flat bar (-50.0).
  - `double levelFromDb(double db)`: maps a dBFS reading to a 0.06..1.0 bar height.
  - `InlineRecorder({required List<double> levels, required Duration elapsed, required Duration max})`: stateless live-recording view.
- Consumes `selectedProjectProvider`, `attachmentStoreProvider`, `notesRepoProvider`, and `noteProcessorProvider` from `lib/app/providers.dart`, plus `ProjectHeader` from [projects](../projects/EGM.md).

## Invariants

- Voice state follows `_Rec` (`idle`, `starting`, `recording`, `stopping`). `_startRecording`, `_stopRecording`, and `_cancelRecording` claim their transition synchronously before the first `await`, so double taps cannot start two recordings or stop one twice.
- The `AudioRecorder` is created on first use only, and never after the widget is disposed (`mounted` check before `_recorder.start`).
- A recording stops automatically at `maxRecording` (5 minutes).
- A draft holds at most one recording and one PDF, and any number of photos. `_startRecording` returns when `_voicePath != null`; `_pickPdf` returns when `_pdf != null`.
- `_canSave` is false while saving, recording, or picking. Otherwise it requires an attachment or non-blank text.
- `_save` returns without doing anything when there is no selected project, and snapshots the draft before its first `await`.
- `_save` order is fixed: persist the PDF, persist the recording, persist the photos, `NotesRepository.create`, delete the temporary recording, enqueue `NoteProcessor.process` unawaited. The temporary recording is deleted only after `create` succeeds.
- With nothing typed and no title, the note is titled from the PDF name, else localized `voiceRecording`, else localized `photosTitle`, because no AI title will come.
- Note `source` precedence is PDF, then voice, then text. Photos do not change `source`. `attachmentBytes` is set only with a PDF, and `durationMs` only with a stored recording.
- On failure, `_save`'s `catch` deletes every file in `stored`. Code added between `create` and the end of that `try` must not throw, because the `catch` would delete files that the committed note references.
- `_discardVoice`, `_removePdf`, and `_removeImage` are no-ops while `_saving`, because the save may be copying those files.
- `_levels` never exceeds `kWaveformSamples` entries. `_LevelsPainter` pads with 0.06 and draws the newest sample at the reading end (left in RTL, right in LTR).
- Field limits: title 80 characters, text 5000 characters.
- `test/app_flow_test.dart` finds `add-save`, `add-mic`, and `add-pdf`; `test/screenshots/screens_test.dart` finds `add-mic`. Renaming those keys breaks the tests.

## Side Effects

- Requests `Permission.microphone`, and calls `openAppSettings` when the permission is permanently denied.
- Records AAC-LC mono at 64 kbps to the temp path from `AttachmentStore.newRecordingPath`.
- Opens the system file picker restricted to `pdf`, rejecting names without a `.pdf` extension, or to images.
- Copies attachments into private storage with `AttachmentStore.persist` (`pdf`, `m4a`, and the photo's own extension), and deletes files with `AttachmentStore.deleteQuietly`.
- Inserts the note row through `NotesRepository.create`, then queues analysis through `NoteProcessor.process`.
- `dispose` stops an active recording but does not delete a finished, unsaved temp recording. `AttachmentStore.sweepOrphans` removes it at a later launch once it is older than `sweepGrace`.
- Navigates with `context.go('/notes')` after a successful save, and shows toasts.

## Localization

Composer copy, picker/recorder errors and accessibility labels use `context.l10n`. File-only recording/photo titles are resolved with the draft snapshot before asynchronous file copies. The file hint uses `bodyHintWithFileLinks`; section 15 UX is not implemented. Asymmetric composer/chip insets mirror, and waveform time flow follows `Directionality`.

## Verification

- Run: `flutter analyze && flutter test`
