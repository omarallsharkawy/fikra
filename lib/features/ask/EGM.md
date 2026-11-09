# Ask

## Overview

The chat tab, mounted at `/ask` by `lib/app/router.dart`. The user asks a question about the selected project, and the answer is stored with the IDs of the notes it came from.

## Interface

- `ask_screen.dart`
  - `AskScreen`: `ConsumerStatefulWidget` with no parameters.
- Consumes `selectedProjectProvider`, `selectedChatProvider`, `selectedNotesProvider`, `chatRepoProvider`, `notesRepoProvider`, and `aiServiceProvider` from `lib/app/providers.dart`, plus `ProjectHeader` from [projects](../projects/EGM.md) and `noteTitle` from [shared](../shared/EGM.md).

## Invariants

- `_send` trims the question and returns when it is blank, when no project is selected, or while `_thinking` is true.
- The project is read once at the start of `_send`, so the answer is stored on the project that was asked even if the selection changes.
- The user message is stored before the AI call. Typed input is cleared only after that store succeeds; a preset suggestion never clears the input.
- `AiService.ask` receives the project's notes from `NotesRepository.notesOf` and is limited to a 60-second timeout.
- If the AI call fails, the stored user message remains with no answer, and the screen shows a toast.
- A message animates only when its ID arrives after the current project's first load. `_seen` resets when the selected project changes.
- A source whose note no longer exists renders as a deleted-note row with its tap disabled.
- Suggestions come from the first three notes with a non-blank title.
- Clearing the chat is unavailable while `_thinking`, and requires `confirmDestructive`. It affects chat entries only.
- The question field is limited to 500 characters.

## Side Effects

- Inserts and deletes chat rows through `ChatRepository.add` and `ChatRepository.clear`.
- Calls `AiService.ask`.
- Pushes `/note/<id>` from a source row, without an `extra` note.
- Shows toasts and invalidates `selectedChatProvider` on retry.

## Verification

- Run: `flutter analyze && flutter test`
