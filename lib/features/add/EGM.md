# Add

## Overview

The composer tab, mounted at `/add` by `lib/app/router.dart`. It builds one note from typed text plus any of one voice recording, one PDF, and photos. The note is saved first, then queued for AI analysis of its typed text. Attachments stay on the device.

## Interface

- `add_screen.dart`
  - `AddScreen`: `ConsumerStatefulWidget` with no parameters.
  - Toolbar widget keys: `ValueKey('add-mic')`, `ValueKey('add-pdf')`, `ValueKey('add-image')`, `ValueKey('add-save')`, `ValueKey('add-stop')`, `ValueKey('add-cancel-rec')`.
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
- With nothing typed and no title, the note is titled from the PDF name, else `تسجيل صوتي`, else `صور`, because no AI title will come.
- Note `source` precedence is PDF, then voice, then text. Photos do not change `source`. `attachmentBytes` is set only with a PDF, and `durationMs` only with a stored recording.
- On failure, `_save`'s `catch` deletes every file in `stored`. Code added between `create` and the end of that `try` must not throw, because the `catch` would delete files that the committed note references.
- `_discardVoice`, `_removePdf`, and `_removeImage` are no-ops while `_saving`, because the save may be copying those files.
- `_levels` never exceeds `kWaveformSamples` entries. `_LevelsPainter` pads with 0.06 and draws the newest sample on the left (RTL time flow).
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

## Verification

- Run: `flutter analyze && flutter test`
