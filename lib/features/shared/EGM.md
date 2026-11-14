# Shared

## Overview

Note display helpers, attachment editing shared by Add and Edit, the link picker and link actions, the project picker, note groups (sheet, form, filter, options), the move confirmation and the selection bar and actions used by the notes list.

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

## Project picker (links phase 3)

- `project_picker.dart`: `showProjectPicker(context, {required title, required excludeProjectId, required empty})` opens a `showFikraSheet` that watches `projectsProvider`, lists every other project as a `ProjectRow` (key `project-pick-<id>`) with its note count, and pops with the picked `Project` (null when dismissed). With no other project it shows `empty` (key `project-picker-empty`). Built for one note now; a later phase reuses it for moving several notes.
- `ProjectRow({project, count, onTap, selected = false, onMore})`: the project row that used to be private in `project_header.dart` (`_ProjectRow`), now shared. The options control appears only with `onMore`; without it the start padding is 16 instead of 8.

## Shared link choices (links phase 4)

`link_pairs.dart` exposes pure generic `uniqueLinkPairs`: skip self pairs, retain first row for each unordered pair, replace a suggestion only with the first user row. Both `linksOfNote` and the isolate-safe graph use it; existing note-page ordering/filtering stays the same.

`note_link_actions.dart` moved from note_details and exports `showLinkOptions` and `changeLinkPair`. The existing user options, private reason editor, update/error behavior and keys are retained. Optional source note makes graph options name both endpoints. Suggestions use the same sheet with the shared Suggested tag and accept/reject pair operations, safe if analysis replaced the row. A one-choice guard prevents repeated sheet actions; operations capture their repository and live toast context before closing. User removal still requires confirmation and the caller's removal callback. No schema, new copy, colours or motion tokens.

## Selection, groups and moving several notes (links phase 5a)

None of these assume the notes list: they take ids, notes, a project id or callbacks.

- `selection_bar.dart`: `SelectionHeader({count, onClose})` (keys `selection-close`, `selection-count`; live-region count) and `SelectionActionBar({actions, note})` with `SelectionAction({key, icon, label, onTap, danger, disabledHint})`. Every action is at least 48 dp wide and 56 dp tall with its label as semantics label; a disabled one is at 0.4 opacity with `disabledHint`. Labels are measured (`TextPainter` with the ambient style, scaler and locale): when all fit on one line each keeps its width plus an equal share of the rest; otherwise the bar scrolls sideways (`selection-bar-scroll`) at natural widths, so no label is clipped at any text size.
- `selection_actions.dart`: `maxLinkTogether` (6), `selectionBusyProvider` (`SelectionGuard`: `claim()`/`release()`, one selection action or Undo at a time app-wide; Undo reads it through the `ProviderContainer`, so it works after the page closed, and shows `undoFailed` when the guard is taken) and the flows, each returning whether to end the selection:
  - `linkTogether`: one `linkNotesForUndo` call per note with the later ones (n−1 calls); a failure puts the pairs linked so far back (`undoLinks`) and shows `linkFailed`. Success shows `linksAdded(created)` (zero form, no Undo, when all pairs were already yours) with Undo calling `undoLinks`: each pair gets back exactly the rows it had (none, its suggestion, its rejection); pairs removed by hand, moved or deleted since are left alone.
  - `groupNotes`: `showGroupSheet`, then the new-group form if chosen (`create`), then `assignNotes`; if the assignment fails a group created in this flow is deleted. Undo reads the project's notes again and puts back only those still in the project and still in the group this action gave them, each in its previous group, or no group when that group is gone; then a group created by this action is deleted if it still exists and has no notes and no sub-groups. Rule errors show their own message (`runGroupAction`).
  - `moveNotesTo`: `showProjectPicker`, then `confirmMove` with the totals (`moveNotesTitle`/`moveNotesBody`, or the single-note strings for one note), `moveNotes` (atomic), `NoteProcessor.relink` not awaited, `notesMoved` toast. No Undo.
  - `deleteNotes`: one `confirmDestructive` (`deleteNotesTitle`/`deleteNotesBody`), then `delete` per note inside `runAction`, stopping at the first failure (`deleteNotesFailed`); files go with each note. No Undo.
- `move_confirm.dart`: `MoveImpact`, `moveMessage(l10n, impact, {notes})` and `confirmMove(...)`, extracted from the note page: after confirm it reads the impact again and shows the dialog again while the numbers changed. The note page uses it with its existing strings and behaviour.
- `note_groups.dart`: `groupsOfProjectProvider` (StreamProvider family over `GroupsRepository.watchGroups`), `groupColors`/`groupColor`/`groupColorName` (0 accent, 1 success, 2 warning, 3 meta; null = none), `groupRuleMessage` (one message per `GroupRuleReason`), `groupTree` (top-level then children), `groupWithChildren`, `groupNoteCounts`, `runGroupAction`, `GroupDot`, `GroupTag` (bordered, icon + name, `noteGroupA11y`).
- `group_sheet.dart`: `showGroupSheet(context, {projectId, canRemove})` → sealed `GroupPick` (`GroupPickExisting`, `GroupPickNew`, `GroupPickNone`); rows `group-pick-<id>` with counts, sub-groups indented with a direction-following arrow, `group-pick-new`, `group-pick-none` (only when a note has a group), `group-sheet-empty`. `GroupRow` is public.
- `group_form.dart`: `showNewGroupForm` (name up to `groupNameMaxLength` 40, colour, optional top-level parent; keys `group-color-<n|none>`, `group-parent-none`, `group-parent-<id>`, `group-create`), `askGroupName` (`group-rename-save`); both buttons use `growForText`, so large text grows them instead of clipping, `GroupColorPicker`, `ChoiceTag` (wraps up to two lines; optional `semanticLabel` replaces the name for screen readers while keeping its selected state and long-press action; a null `onTap` disables it). A picked parent is kept even if it stops being top-level meanwhile, so the repository's `invalidParent` message shows.
- `group_options.dart`: `showGroupOptions(context, ref, group)` (one-choice guard; the sheet closes before the next step): rename, colour, put inside a group (top-level candidates only; for a group with sub-groups the option is shown disabled, not tappable, with `groupRuleHasChildren` under it (`group-nest-reason`) and as its semantics hint; a sub-group added while the parent list is open gets the repository's `hasChildren` message), take out of its parent, delete (`confirmDestructive` with `danger: false`: notes stay, sub-groups move out).
- `group_filter.dart`: `GroupFilterRow({groups, selectedId, onSelect, onOptions})`: `group-filter-all`, `group-filter-<id>` (dot + name, capped width), a second row of sub-groups (`group-filter-children`) when a parent with children is selected, tapping the selected chip goes up a level, long press or `group-filter-options` on the selected chip opens the options. Graph-only flags (defaults keep the notes list unchanged): `navigation: true` makes chips move the graph instead of filtering, with no "All" chip, no clear/options button, no selected look and the `graphNavigateGroup` semantics label; `enabled: false` dims the row to 0.4 and ignores taps and long presses (graph selection mode).

## Graph reuse (phase 5b)

`selection_actions.dart` exposes `assignSelectionGroup(context, ref, {projectId, notes, target, created})`, extracted from groupNotes after the picker/form. The notes-list flow delegates unchanged. Graph topic conversion supplies its newly created target and holds the same selectionBusyProvider guard. Assignment failure cleanup, localized toast, safe Undo (leave moved/regrouped notes alone), and deletion of a created group only while empty all use this one implementation. No repository/schema or existing public-name changes.

Phase 5b review: note_selection_actions.dart exports noteSelectionActions(context, ref, {selection, onDone}), the single four-action bar/runner used by notes and graph. Call with the owning screen’s context/ref: the bar can disappear while assignment is saving. Actions snapshot current selected notes, share selectionBusyProvider with Undo, hide old toasts and let the caller apply its original set-identity completion rule. Existing selection keys and 2–6 link rules remain. assignSelectionGroup adds freshlyRead:false; true uses a freshly fetched repository snapshot without stale-provider filtering, while the notes picker keeps its existing pruning behaviour.

## Saved recording intent (phase 2)

New voice previews (id == null) show an existing ChoiceTag, trAfterSave, when auto-transcription is off. Its selected state updates AttachmentDraft.transcribe without touching the temporary audio file. Saved attachment previews have no toggle; automatic mode makes the save policy select all new voice drafts. Capture/AAC settings, microphone ownership, five-minute limit and cleanup behavior are unchanged. Save paths consume the current persisted setting, so a loading chip cannot accidentally disable auto mode. All inference is deferred until copies and the note commit succeed.

Voice preview keys retain path/position identity when a new immutable draft is made by the transcription toggle, preserving player state/playback across that toggle.
