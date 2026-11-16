# lib

## Overview

All application source for FIKRA, a local-first Arabic and English notes app for Android. `main.dart` starts the app. The four subpackages split the code by role: `app` wires it together, `core` holds shared presentation code, `data` owns storage and the AI boundary, and `features` holds the screens.

## Interface

- `main.dart`: `main()`.
- [l10n](./l10n/EGM.md): Arabic/English ARB messages, generated `AppLocalizations`, context extension, and demo vocabulary.
- Subpackages:
  - [app](./app/EGM.md): `FikraApp`, `routerProvider`, the Riverpod providers, `AppShell`, `appMode`.
  - [core](./core/EGM.md): `Fmt`, theme tokens, motion tokens, shared widgets.
  - [data](./data/EGM.md): repository interfaces and their local implementations, `AiService`, `AttachmentStore`, `openWithSystem`, `NoteProcessor`, `FikraDatabase`.
  - [features](./features/EGM.md): one folder per screen group.

## Invariants

- [`main.dart:main`] throws `UnsupportedError` before `runApp` when `appMode == AppMode.connected`. Connected mode must not run on the demo services. This check must be removed when the backend is wired in.
- [`main.dart:main`] calls `initializeDateFormatting()` before `runApp`. `Fmt` date formatting depends on it.

## Side Effects

- [`main.dart:main`] loads date symbols for supported locales and starts the widget tree inside a `ProviderScope`.

## Verification

- Run: `flutter analyze && flutter test`

Attachment persistence uses `NoteAttachments` (introduced in v5; current schema v7). Add and Edit share the draft editor; copies precede atomic repository saves, and stored-file deletion follows commit. Cards share one per-project attachment stream. All files and recording operations remain local.

Schema v6 adds local user links, dismissed-pair memory and note groups. Repositories expose moves and grouping without widget changes; relink jobs share the analysis queue and preserve rewrite/status fields.

Schema v7 stores attachment transcription state and provenance. Settings persist optional auto-transcription (off by default), saved recordings enter a separate durable queue, and details/card streams expose progress. A local engine adapter beside the voice experiment implements the data-layer TranscriptionEngine seam; app wiring shares the Whisper lock with trial file/live inference. No external transcription services are implemented.

Phase 3 adds user-configured remote transcription behind the same queue seam. Config/consent/selection use the existing settings table, credentials use Keystore-backed secure storage, and the composition root selects local/remote adapters at job start. Consent gates both trials and saved-note requests; remote data is never logged. This is independent of the still-unimplemented connected AI backend.
