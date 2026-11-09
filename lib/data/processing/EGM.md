# Note Processing Queue

## Overview

Runs the AI pass after a note is saved and moves it from `processing` to
`ready` or `failed`. The note is already stored before this runs, so a failed
analysis never loses what the user wrote.

## Interface

From `note_processor.dart`:

- `class NoteProcessor`
  - `NoteProcessor(NotesRepository notes, AiService ai, {Duration timeout = const Duration(seconds: 90)})`
  - `Future<void> process(Note note)`: queues the note and completes when its job is done.
  - `Future<void> retry(String id)`: re-queues the note if it still exists, and waits for the job.
  - `Future<void> resumeInterrupted()`: re-queues every note left in `processing` after the app was killed. It does not wait for those jobs.

Depends on `NotesRepository` from [`../EGM.md`](../EGM.md) and `AiService` from
[`../ai/EGM.md`](../ai/EGM.md).

## Invariants

- Jobs run one at a time in FIFO order, so each analysis sees the concepts of the notes processed before it. A failed job does not stall the queue.
- `process` uses only `note.id`. Each job re-reads the note when it starts, and that snapshot is the `basis` for `applyInsights`, so edits made while the AI runs win.
- A note deleted while queued is skipped without any write.
- A note whose `originalText` is blank goes straight to `ready`, and `AiService` is not called. Attachments are never parsed.
- Any error during analysis or while applying the result marks the note `failed`, including a timeout. A job that exceeds `timeout` is failed and the queue moves on, but the underlying `analyze` call is not cancelled; its result is discarded.
- The doc comment on `process` says the future never throws, but the initial `watchNote(id).first` read sits outside the `try`. If that read fails, the error reaches the future returned by `process` while the queue still continues.

## Side Effects

- Updates note status, insights and links through `NotesRepository`.
- Calls `AiService.analyze`. The demo implementation is offline; the doc comment on `AiService` says the connected build will call the backend API.
- `lib/app/providers.dart` calls `resumeInterrupted` once at launch.

## Verification

- Run: `flutter analyze && flutter test`
