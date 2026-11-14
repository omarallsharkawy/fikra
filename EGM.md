# FIKRA Blueprint

## System Overview

FIKRA is a Flutter Android app for Arabic and English notes. Notes, projects, links, and chat history are stored on the device in a Drift SQLite database, and attachment files are stored in the app's private documents directory.

The current build is the demo. `AiService` is the boundary to the backend, and the demo implementation sits behind it. Voice recordings, PDFs, and photos stay on the device and are never uploaded; typed note text, which includes locally made recording transcripts, is analyzed (never edits or PDF text). PDFs are parsed locally by PDFium for display. `FIKRA_MODE=connected` is rejected at startup because no backend implementation exists yet.

```text
features -> app/providers -> data repositories -> Drift SQLite
                          -> NoteProcessor -> AiService (DemoAiService today)
                          -> AttachmentStore -> private files
```

A saved note is written to the database first. `NoteProcessor` then runs analysis one note at a time and moves the note to `ready` or `failed`. Screens update from Drift streams through Riverpod providers.

Not covered by these contracts: `android/` (a default Flutter host), `integration_test/`, `test_driver/`, and generated `*.g.dart` files. Tests have their own `test/EGM.md` contract.

## Subdirectories & System Boundaries

- lib: [./lib/EGM.md](./lib/EGM.md) - All application source and the `main()` entry point.
- lib/app: [./lib/app/EGM.md](./lib/app/EGM.md) - Build mode, providers, routes, and the four-tab shell.
- lib/core: [./lib/core/EGM.md](./lib/core/EGM.md) - Formatting, theme, motion, and shared widgets. Imports nothing from `app`, `data`, or `features`.
- lib/data: [./lib/data/EGM.md](./lib/data/EGM.md) - Repositories, schema, files, analysis queue, and the AI boundary.
- lib/l10n: [./lib/l10n/EGM.md](./lib/l10n/EGM.md) - Approved Arabic/English copy, generated lookups, and demo vocabulary.
- lib/features: [./lib/features/EGM.md](./lib/features/EGM.md) - Screens, grouped by folder.

## Global Invariants

- A note is stored before analysis runs, so an analysis failure never loses it (`lib/features/add`, `lib/data/processing`).
- A note with no typed text (recording transcripts count as typed text) goes straight to `ready` without calling `AiService` (`lib/data/processing`).
- `Notes.originalText` is never overwritten (`lib/data/local`).
- `applyInsights` treats AI output as untrusted and validates link targets (`lib/data`).
- Every migration step must be atomic and safe to re-run (`lib/data/local`).
- Pushed routes must use `_pushed` in `lib/app/router.dart`, or go_router falls back to no transition.
- Connected mode must not run on the demo services (`lib/main.dart`, `lib/app/providers.dart`).

## Global Side Effects

- Reads and writes the on-device SQLite database named `fikra`.
- Creates and deletes files under `attachments/` in private storage, and `rec_*` recordings in the temp directory.
- Requests microphone permission and opens the system file picker (`lib/features/add`).
- Displays local PDFs in the app with pdfrx; photos and the explicit PDF open-elsewhere action use `openWithSystem` (`lib/data/files`).
- The demo build makes no network calls from `lib/data/ai`.

## System Verification

- Run: `flutter analyze && flutter test`

## Languages

- Arabic is RTL; English is LTR. A persisted language preference resolves through `appLocaleProvider`; device mode uses English only for an English device and Arabic otherwise.
- UI copy lives in `lib/l10n`, based on `docs/plans/copy-glossary.md`. Stored content, topics, groups and answers retain their creation language.

## Multi-attachment storage (v5)

A note owns ordered rows in `note_attachments`, with cascading deletion. Add and saved-note Edit share capture/preview code. Draft removals never delete disk files before commit; failed saves clean new copies and retain the draft. Startup sweeping queries all new rows only after the database migration succeeds; failed opening prevents maintenance. A one-hour grace protects files copied by an in-flight save. Cards share a batched project stream, and PDFs route by note plus attachment ID.

Phone follow-up fixes classify locked PDFs with a specific non-retry error, share graph/title fallback text, centre zoom on the graph viewport and adapt rewrite actions to localized label widths and large text. File-size LTR and transition tap behavior are covered by regressions without further gesture or formatting changes.

## Local links and groups (v6)

The data layer now supports user links, rejected-pair tombstones, two-level note groups and atomic moves between projects. These operations have no UI in this phase and never send user links or groups to a server. Labels remain NOT NULL strings; no reason is stored as `''`.

## Saved voice transcription (v7)

Voice recording files remain local. Optional on-device transcription is off by default; Add/Edit persist requests only for new recordings after save, or details queues one manually. A durable attachment FIFO shares a process-wide Whisper lease with the voice experiment. Transcript/engine/status/time live on each attachment. A transcript counts as text the user wrote: a transactional append adds it once to originalText and, when the note has an edit, to editedText, so restoring the original keeps it and a pending proposal is dropped as for a user edit. Search and card previews use the current body; analysis uses originalText only, so each transcript is analyzed once. Killed jobs resume at launch, at most twice per request: after a second kill during the same recording's transcription it is marked failed instead of restarting, so a native crash or out-of-memory kill cannot repeat on every launch; while jobs run, an Android foreground service (`TranscriptionService`, mediaProcessing on Android 15+, dataSync on 10–14) with a low-importance notification keeps the process alive after the user leaves the app. Notification permission is asked once, the first time a transcription is queued; refusing it never blocks saving. No external transcription provider is introduced.
