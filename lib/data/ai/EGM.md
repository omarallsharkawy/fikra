# AI Service Seam

## Overview

Defines the boundary between the app and the backend's AI layer, plus the
offline simulation used by the demo build. Screens and `NoteProcessor` depend
only on the abstract interfaces. No connected implementation exists in this
directory.
`lib/app/providers.dart` selects the implementation by `AppMode`, and its
`AppMode.connected` branches currently throw `UnimplementedError`.

## Interface

From `ai_service.dart`:

- `abstract interface class AiService`
  - `Future<NoteInsights> analyze(Note note, List<Note> projectNotes)`: rewrite, tag and link a saved note from its typed text.
  - `Future<ChatAnswer> ask(String question, List<Note> projectNotes)`: answer using only the notes of one project.
- `class NoteInsights`: `title`, `concepts`, `cluster`, `links` (required); `proposedText` (nullable).
- `class ProposedLink`: `targetId`, `label`, `strength`.
- `class ChatAnswer`: `text`, `sourceIds`, `found`.

From `demo_ai_service.dart`:

- `class DemoAiService implements AiService`
  - `DemoAiService({Duration latency = const Duration(milliseconds: 2500)})`
  - Static helpers, public for tests and seeding: `detectConcepts(String)`, `clusterFor(String)`, `improve(String)`, `suggestTitle(String)`.

Uses `Note` and `NoteSource` from [`../local/EGM.md`](../local/EGM.md).

## Invariants

Interface contract:

- `projectNotes` passed to `analyze` may include `note` itself; implementations must not link a note to itself. `DemoAiService` skips it by id. `NotesRepository.applyInsights` also drops self links.
- AI output is treated as untrusted by the caller: `applyInsights` validates link targets, strengths and labels. See [`../EGM.md`](../EGM.md).

`DemoAiService.analyze`:

- Deterministic given its inputs, offline, and awaits `latency` before computing.
- `proposedText` is only produced when the rewrite differs from the trimmed original and is non-empty.
- `title` keeps a non-blank `note.title`; otherwise it comes from `suggestTitle`.
- `links` holds at most 4 entries, sorted by descending `strength`. Strength is the Jaccard ratio of concept sets, and only notes sharing at least one concept qualify.

`DemoAiService.ask`:

- Uses a fixed 1200 ms delay. The `latency` constructor argument does not affect it.
- Scores +1 per query token found in the note's title, display text and concepts, and +2 per shared concept. Only the top 3 notes with a score above 0 are cited.
- With no match it returns `found: false` and empty `sourceIds`.

Helpers:

- `detectConcepts` returns at most 5 distinct concepts, in dictionary order.
- Latin dictionary keys match whole words only ("api" does not match "rapid"). Arabic keys match as substrings so prefixed forms still count.
- `clusterFor` returns the cluster with the most keyword hits, or `'أفكار عامة'` when none match.
- `suggestTitle` uses the first 6 words, appending `…` when truncated, and returns `'نوت بدون عنوان'` for empty content.

## Side Effects

- `DemoAiService` only waits on timers. It performs no network, disk or database access.
- Nothing in this directory writes results back. Persistence is the caller's job.

## Verification

- Run: `flutter analyze && flutter test`
