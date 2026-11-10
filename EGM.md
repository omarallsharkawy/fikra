# FIKRA Blueprint

## System Overview

FIKRA is a Flutter Android app for Arabic and English notes. Notes, projects, links, and chat history are stored on the device in a Drift SQLite database, and attachment files are stored in the app's private documents directory.

The current build is the demo. `AiService` is the boundary to the backend, and the demo implementation sits behind it. Voice recordings, PDFs, and photos stay on the device and are never parsed; only typed text is analyzed. `FIKRA_MODE=connected` is rejected at startup because no backend implementation exists yet.

```text
features -> app/providers -> data repositories -> Drift SQLite
                          -> NoteProcessor -> AiService (DemoAiService today)
                          -> AttachmentStore -> private files
```

A saved note is written to the database first. `NoteProcessor` then runs analysis one note at a time and moves the note to `ready` or `failed`. Screens update from Drift streams through Riverpod providers.

Not covered by these contracts: `android/` (a default Flutter host), `test/`, `integration_test/`, `test_driver/`, and generated `*.g.dart` files.

## Subdirectories & System Boundaries

- lib: [./lib/EGM.md](./lib/EGM.md) - All application source and the `main()` entry point.
- lib/app: [./lib/app/EGM.md](./lib/app/EGM.md) - Build mode, providers, routes, and the four-tab shell.
- lib/core: [./lib/core/EGM.md](./lib/core/EGM.md) - Formatting, theme, motion, and shared widgets. Imports nothing from `app`, `data`, or `features`.
- lib/data: [./lib/data/EGM.md](./lib/data/EGM.md) - Repositories, schema, files, analysis queue, and the AI boundary.
- lib/l10n: [./lib/l10n/EGM.md](./lib/l10n/EGM.md) - Approved Arabic/English copy, generated lookups, and demo vocabulary.
- lib/features: [./lib/features/EGM.md](./lib/features/EGM.md) - Screens, grouped by folder.

## Global Invariants

- A note is stored before analysis runs, so an analysis failure never loses it (`lib/features/add`, `lib/data/processing`).
- A note with no typed text goes straight to `ready` without calling `AiService` (`lib/data/processing`).
- `Notes.originalText` is never overwritten (`lib/data/local`).
- `applyInsights` treats AI output as untrusted and validates link targets (`lib/data`).
- Every migration step must be atomic and safe to re-run (`lib/data/local`).
- Pushed routes must use `_pushed` in `lib/app/router.dart`, or go_router falls back to no transition.
- Connected mode must not run on the demo services (`lib/main.dart`, `lib/app/providers.dart`).

## Global Side Effects

- Reads and writes the on-device SQLite database named `fikra`.
- Creates and deletes files under `attachments/` in private storage, and `rec_*` recordings in the temp directory.
- Requests microphone permission and opens the system file picker (`lib/features/add`).
- Hands PDFs and photos to other apps through `openWithSystem` (`lib/data/files`).
- The demo build makes no network calls from `lib/data/ai`.

## System Verification

- Run: `flutter analyze && flutter test`

## Languages

- Arabic is RTL; English is LTR. A persisted language preference resolves through `appLocaleProvider`; device mode uses English only for an English device and Arabic otherwise.
- UI copy lives in `lib/l10n`, based on `docs/plans/copy-glossary.md`. Stored content, topics, groups and answers retain their creation language.
