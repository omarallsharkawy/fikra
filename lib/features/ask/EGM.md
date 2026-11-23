# Ask

## Overview

The chat tab, mounted at `/ask` by `lib/app/router.dart`. The user asks a question about the selected project, and the answer is stored with the IDs of the notes it came from.

## Interface

- `ask_screen.dart`
  - `AskScreen`: `ConsumerStatefulWidget` with no parameters.
- Consumes `selectedProjectProvider`, `selectedChatProvider`, `selectedNotesProvider`, `chatRepoProvider`, `notesRepoProvider`, and `aiServiceProvider` from `lib/app/providers.dart`, plus `ProjectHeader` from [projects](../projects/EGM.md) and `noteTitle` from [shared](../shared/EGM.md).

## Invariants

- `_send` trims the question and returns when it is blank, when no project is selected, or while that project is already in `_thinkingProjects` (per-project pending state, so another project stays interactive).
- The project ID and a controller-listener `_draftRevision` are captured before the first await. Typed input clears only after `chat.add` succeeds while still mounted, on the same selected project, and with an unchanged draft revision; a preset suggestion never clears manual input. Writes stay scoped to the captured project, and error toasts or auto-scrolls are skipped if the user switched away.
- `AiService.ask` receives the project's notes from `NotesRepository.notesOf` and is limited to a 60-second timeout.
- If the AI call fails, the stored user message remains with no answer, and the screen shows a toast.
- A message animates only when its ID arrives after the current project's first load. `_seen` resets when the selected project changes.
- A source whose note is not among the selected project's notes (moved to another project, or deleted) renders as a `sourceMissing` row ("Note no longer in this project", `sourceMissingA11y` for TalkBack) with its tap disabled, so a moved note never opens from the old project's chat.
- Suggestions come from the first three notes with a non-blank title.
- Clearing the chat is unavailable while `_thinking`, and requires `confirmDestructive`. It affects chat entries only.
- The question field is limited to 500 characters.

## Side Effects

- Inserts and deletes chat rows through `ChatRepository.add` and `ChatRepository.clear`.
- Calls `AiService.ask`.
- Pushes `/note/<id>` from a source row, without an `extra` note.
- Shows toasts and invalidates `selectedChatProvider` on retry.

## Localization

Suggestions and source semantics use typed localized placeholders. Stored questions/answers remain unchanged. The demo service resolves new answers in the active language at output time.

## Verification

- Run: `flutter analyze && flutter test`

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.
User bubbles and source rows are opaque neutral chip; assistant answers are opaque surface.

## Floating navigation (redesign phase 2)

The complete chat/composer column consumes NavigationInset.of(context), keeping its fixed input row and both message/empty scroll lists above the floating bar. With the keyboard open the shell supplies zero clearance and hides navigation; Scaffold still handles the IME resize.

## Ordering & IA (redesign phase 4)

When chat entries exist, `AskScreen` renders `ask-clear-chat` via `HeaderActionButton` (visible caption `clear`, semantic label `clearChatA11y`, disabled while `_thinking`).

## Finishing (redesign phase 8)

`AskScreen` wraps `notFoundInNotes` in `Flexible` and sizes `_SourceRow`'s index badge with `minWidth/minHeight: 22` so large text wraps and grows cleanly at 2.0× scale.

## Brand redesign (phase 1a)

`_UserBubble` uses solid `brandBlue` fill with `onBrandBlue` ink (`FikraRadius.lg`); the send button uses solid `brandLime` with `onBrandLime` ink; the sources header uses 12.5 sp `meta`.
