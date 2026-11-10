# Shared

## Overview

Note display helpers and attachment editing shared by Add and Edit.

## Interface

- `note_presentation.dart`
  - `IconData sourceIcon(NoteSource s)`: icon for one note source. Currently called only inside this file.
  - `List<IconData> sourceIcons(Note n, [List<NoteAttachment> attachments])`: every source of a note.
  - `String noteTitleText(BuildContext context, String title)`: shared fallback for full notes and graph projections.
  - `String noteTitle(BuildContext context, Note n)`: the note's title, or a fallback label when the title is blank.
- `open_attachment.dart`
  - `Future<void> openAttachment(BuildContext context, WidgetRef ref, String path)`: opens a file in another app, and shows a toast if it returns false or throws. Used for photos and the PDF viewer’s explicit open-elsewhere action.

## Invariants

- `sourceIcons`/`attachmentIcons` use new-table rows, in PDF/voice/image order, with the original source icon as fallback. `attachmentIcons` also returns counts for cards; no legacy attachment columns are consulted.
- `noteTitle` checks the trimmed title for blankness but returns the untrimmed title.
- `noteTitle` and the graph’s `_graphTitle` both delegate to `noteTitleText`. All graph display surfaces, including node text, use this shared fallback.

## Side Effects

- `openAttachment` starts another app through `fileOpenerProvider`. Display helpers are pure; the shared editor owns local picking/recording side effects documented below.

## Localization

`noteTitle(BuildContext context, Note n)` resolves only the blank-title fallback using `context.l10n`. `openAttachment` uses the localized open-file failure; stored file names and titles are returned unchanged.

## Verification

- Run: `flutter analyze && flutter test`

## Shared attachment editing

`attachment_editor.dart` and its parts (`attachment_files`, `attachment_voice`, `attachment_toolbar`, `attachment_chips`, `mic_permission_card`) extract the existing Add controls for Add and Edit. `AttachmentEditing<T>` owns ordered `AttachmentDraft` files, picking/saving state, recorder transitions, permission status, waveform, and cleanup. It exposes previews, toolbar, recording and permission widgets; screens own text and save/leave behavior. `inline_recorder.dart` preserves `InlineRecorder`, `levelFromDb` and the existing constants/motion.

PDF picking uses multi-file `FilePicker.pickFiles` every time; images retain multi-picking. No action starts while saving, picking or recording. Record transitions synchronously claim local state and the app-wide microphone lease before awaits, await playback stop before native start, stop at five minutes, and clean temporary paths even if disposed during start/stop. Temporary voices are deleted on discard/dispose; picked source files are not deleted by a failed save. Edit overrides `confirmAttachmentRemoval` for saved attachments (`id != null`) only; saved-file removal only changes the draft. Consecutive images share a strip and all preview order follows the draft. PDF size Text is explicitly LTR; filenames retain ambient alignment.

The toolbar keeps its keys and styling; Edit hides its round Save and uses the existing Save changes button. All players share the core playback coordinator. `RecordingActivity` releases ownership only for the owning editor after native stop/cancel/dispose; failed permission/start and pending disposal are covered. Cancellation failure falls back to disposing the recorder. Another editor cannot start while a native start or cancellation is outstanding. This folder now depends on app providers and the local data/file boundaries for editing, as well as the existing presentation/opener helpers.

`attachmentTitle(l10n, draft)` centralizes legacy auto-titles for Add and Edit: localized voiceRecording, PDF basename without extension, or photosTitle. It never appends counts.
