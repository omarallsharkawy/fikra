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
- Only `originalText` is analyzed. A recording transcript counts as text the user wrote: `TranscriptionQueue` appends it to `originalText` once, so each transcript is analyzed once, the same way as typed text. Edits, accepted rewrites and PDF text are not analyzed; a transcript the user later deletes from an edit is still in `originalText` and still analyzed, as edits never change analysis. If `originalText` is blank the note goes straight to `ready` and `AiService` is not called.
- Proposals follow the same rule as without recordings: `applyInsights` keeps a proposal only while the note has no edit and nothing changed since the basis, so edits made meanwhile win.
- In normal processing, any error during analysis or while applying the result marks the note `failed`, including a timeout. A job that exceeds `timeout` is failed and the queue moves on, but the underlying `analyze` call is not cancelled; its result is discarded.
- The doc comment on `process` says the future never throws, and its re-read and failure marking are guarded, so later jobs still continue.

## Side Effects

- Updates note status, insights and links through `NotesRepository`.
- Calls `AiService.analyze`. The demo implementation is offline; the doc comment on `AiService` says the connected build will call the backend API.
- `lib/app/providers.dart` calls `resumeInterrupted` once at launch.

## Verification

- Run: `flutter analyze && flutter test`

## Relinking

`Future<void> relink(Iterable<String> ids)` appends unique IDs to the same FIFO queue. A job rereads the note and its current project when it starts; missing/blank notes are skipped. It calls applyInsights with linksOnly and never marks processing, ready or failed. Analysis errors/timeouts and apply errors are swallowed; analysis failure performs no write, and transactional apply failures roll back. Subsequent jobs still run.

## Recording transcription queue

TranscriptionEngine has id and transcribe(audioPath, language); TranscriptionEngineFactory resolves the current adapter/settings at each job start. TranscriptionQueue depends only on this seam, the existing key/value settings and SQLite, not Whisper or provider request formats. Phase 3 resolves the selected, consented local/remote adapter in the factory without changing queue calls. This remains independent of the existing unsupported connected AI/backend mode.

Enqueue reserves its FIFO slot synchronously, deduplicates queued/running attachment IDs in-process, persists queued with a transactionally allocated request order and returns without waiting for inference. saved(noteId, newPaths) wakes the queued requests already atomically saved with new attachment rows. Start re-reads attachment and parent inside a transaction; deleted rows/notes and non-voice attachments are skipped without job writes. Jobs run serially; failures persist stable codes (modelMissing, busy, audioUnreadable, other) and never poison the next slot. Database-write failures are logged, leaving durable queued/running rows for recovery rather than resurrecting deleted data.

Success transaction re-reads current attachment/body, stores text/engine/completion, and appends with a blank line when this attachment has no previous standalone copied block in the visible text (`displayText`) and no correction. Equal results from different attachment identities each append once. transcriptNoteText retains the previous body marker across differing redos. Standalone-block checks replace substring checks; duplicate blocks still count as present on redo. The transcript counts as text the user wrote: it goes into `originalText`, and into `editedText` too when the note has an edit, so the visible text holds it exactly once, «ارجع للأصل» (`restoreOriginal`) keeps it, and a note that was never edited shows no "improved version". A pending proposal is treated as a user edit treats it: `proposedText` is cleared and `rewrite` returns to none. Accepted or rejected rewrites keep their state. The note becomes processing atomically and the normal NoteProcessor pass is scheduled without holding the audio FIFO behind AI. A scheduling failure is logged and recovered by NoteProcessor at launch.

resumeInterrupted queues queued/running rows by persisted transcriptionOrder, retaining request FIFO after termination (legacy/hand-seeded null orders use creation/position/id ties). Ordinary enqueue ignores completed rows; only explicit redo re-runs one. Save wake-ups accept only the newly copied, requested voice paths, so editing cannot retry an older failed recording by accident. Work continues while the Flutter process runs, and resumes on the next launch after Android kills it.

Keep-alive: `TranscriptionQueue(keepAlive:)` takes a `TranscriptionKeepAlive` (`start(remaining)`, `stop()`; default no-op). `start` is called when a job begins, with the number of recordings left including it, and again when a job joins while one runs, so the notification's count stays current. `stop` is called once the last pending entry leaves the queue, after success, failure, a skipped job or a database error. Keep-alive errors are logged and never stop a job. Rows the crash-loop guard fails at launch, and skipped or completed rows, never start it. The Android implementation and its channel live in `lib/features/voice_text/transcription_service.dart`; tests use `FakeTranscriptionKeepAlive`.

WhisperLock is one process-wide FIFO lease shared by local attachment inference, trial file/live inference and model deletion. Queue acquisition waits up to ten minutes; expired waiters are removed. The test screen declines immediately with its localized busy explanation. A lease is released only after real inference/live shutdown, never via an inference timeout (Whisper cannot cancel). Local calls use four threads and keepModelLoaded false, limiting simultaneous model RAM. External engines need not take the Whisper lease.

Note recordings run as private Whisper runs: the FIKRA_WHISPER log line omits the text (it records `text_chars`) and nothing is added to the experiment's runs.jsonl.

Crash-loop guard: `transcriptionAttempts` counts runs started since the user last asked. The start transaction writes `running` and the incremented count before inference, so a native crash or out-of-memory kill still counts. `resumeInterrupted` re-queues a queued/running row only while attempts < `maxInterruptedAttempts` (2); otherwise it marks the row failed with `interruptedTwice` and does not start the engine. Only a manual request (`enqueue(manual: true)`: transcribe, retry, redo from details) resets the count to 0. Launch recovery and save wake-ups keep it, and edits that rewrite attachment rows carry it over.

## External adapters (phase 3)

The queue, persisted request order, keep-alive and interruptedTwice attempt guard are unchanged. TranscriptionFailureReason additionally supports offline, keyRejected, rateLimited, tooLarge, serviceError, unexpectedResponse, remoteTimeout and consentRequired; the queue stores only these codes. Remote adapters have id remote:<serviceId>, never acquire WhisperLock, and discard provider exception/body text before it can reach queue diagnostics. Engine/config/key selection happens at job start through app providers, not at enqueue time. Success still follows the same append, provenance and normal-analysis transaction.

## Voice 2a policy and corrections

Off rows never resume or start automatically. A details manual request changes policy to afterSave and resets attempts; queue order, single-job execution, keep-alive and crash-loop limits remain unchanged. Job start and completion re-read policy, so turning off a pending recording through Edit prevents a result from being written. Diagnostics retain no raw exception or transcript text.

TranscriptCorrections.save uses attachment ID and expected transcriptRevision. One transaction re-reads attachment and note, rejects stale/deleted data, preserves the machine transcript, writes correction/time/revision and attempts an exact standalone-block replacement. Both originalText and editedText (when set) must each contain exactly one unchanged transcriptNoteText block; no substring replacement is allowed. Missing/changed/duplicate copies keep both note bodies and the old copy marker, and return noteChanged=false so the UI offers an explicit append. Append is revision-checked and avoids adding an already unique identical paragraph. Safe replacement/append updates the marker, clears a pending rewrite, persists processing and schedules/awaits the normal NoteProcessor pass. A saved correction is therefore analyzed as typed transcript text. A redo stores new machine text while retaining correction and marker; use/restore clears the correction through the same safe path.
