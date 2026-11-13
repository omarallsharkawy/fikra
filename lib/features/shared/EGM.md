# Shared

## Overview

Note display helpers, attachment editing shared by Add and Edit, and the link picker shared by the note page (and later the notes list and graph).

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

## Links (links phase 2)

- `note_links.dart`: `linkReasonMaxLength` (80), `typedef NoteLinkEntry = ({Note other, NoteLink link})`, `linksOfNote(noteId, links, notesById)` (one entry per other note in either direction; dismissed rows and missing notes skipped; the user row wins over legacy reverse/duplicate rows, otherwise the first suggestion; your links first newest-first, then suggestions in stored order), `LinkSuggestedTag`, and `LinkReasonField` (FikraField with `maxLength` 80 and an LTR `used/80` counter at the end, key `link-reason`).
- `link_picker.dart` (+ parts `link_picker_row.dart` and `link_picker_layout.dart`): `showLinkPicker(context, {required Note source})` opens a tall `showFikraSheet`; `LinkPickerSheet` watches `notesOfProjectProvider`/`linksOfProjectProvider` of the source's project, lists the other notes newest first in a lazy `ListView.builder`, derives candidates, the id map and link states only when either stream emits (`LinkPickerSheet.derivations` counts that for tests) and memoises the filtered list per query, so a keystroke only filters the cached lower-cased title and text, and multi-selects with check icons and `checked` semantics. Notes you linked are dimmed, say "Already linked" and can't be picked; suggestions show the tag and can be picked. Confirm (`link-confirm`, count in its label, disabled with nothing picked, `_busy` guard) calls `linkNotes` once with every pick and the reason, pops with the number linked and the caller shows `notesLinked`. It pops only if its route is still current: a sheet dismissed while saving keeps the page under it, and the links are saved anyway. A failure keeps the sheet, picks and reason, and shows an inline `StatusBanner` with `linkFailed` (a toast would sit behind the sheet). Empty project, no results and load failure have their own messages. `_PickerLayout` (render object in `link_picker_layout.dart`) gives search and the footer their natural height and the list the rest, but at least 120 dp; inside a `SingleChildScrollView` (key `link-picker-form`) the whole form scrolls only when the controls can't fit (short screen, keyboard, large text, failure banner).
- `linkReasonMaxLength` is `linkLabelMaxLength` from `lib/data/link_label.dart`; field, counter and storage all count grapheme clusters, so what the field shows is what is saved.
