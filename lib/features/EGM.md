# Features

## Overview

One folder per screen group of the FIKRA Flutter app. `lib/app/router.dart` is the only file under `lib/` outside this directory that imports these screens. Features read and write data through the Riverpod providers in `lib/app/providers.dart`.

Shared feature boundaries: `add`, `ask`, `links`, and `notes` use `ProjectHeader` from `projects`; `ask`, `links`, `note_details`, and `notes` use the display helpers in `shared`; `note_details` also uses its external-file opener.

## Subdirectories & Boundaries

- add: [./add/EGM.md](./add/EGM.md) - Composer branch at `/add`, entered by the floating Add button: text, voice recording, and PDF capture, with save-then-analyze ordering.
- ask: [./ask/EGM.md](./ask/EGM.md) - Chat tab at `/ask`: questions answered from the selected project's notes, with sources.
- links: [./links/EGM.md](./links/EGM.md) - Graph tab at `/links`: pure capped layout, moved to an isolate for large projects.
- note_details: [./note_details/EGM.md](./note_details/EGM.md) - Pushed read view, editor, and local PDF viewer at `/note/:id`, `/note/:id/edit`, and `/note/:id/pdf/:attachmentId`.
- notes: [./notes/EGM.md](./notes/EGM.md) - List tab at `/notes`: day-grouped lazy list with cached client-side search, group filter and tags, and selection mode with link/group/move/delete.
- projects: [./projects/EGM.md](./projects/EGM.md) - Shared header, project switcher, name prompt, and the `/welcome` screen.
- settings: [./settings/EGM.md](./settings/EGM.md) - Pushed screen at `/settings`: theme/language selection and full local data wipe.
- shared: [./shared/EGM.md](./shared/EGM.md) - Note display helpers, shared attachment editing, link picker and actions, project picker, note groups, move confirmation, and the selection bar and actions.

## Copy and direction

Every feature uses generated `AppLocalizations` through `context.l10n`; user content remains untouched. Arabic follows RTL and English LTR. Asymmetric insets are directional, and Material back/chevron icons mirror via their built-in `matchTextDirection` metadata.

Add and Edit both use `shared/attachment_editor.dart`; all live attachments come from the v5 table through repository streams.

- voice_text: [./voice_text/EGM.md](./voice_text/EGM.md) - Settings-only on-device transcription experiment. It owns application-support models/trial recordings and the native adapter for the durable saved-recording queue. Settings and saved attachments use the shared database.

Phase 3 voice settings adds user service forms and explicit recipient consent. Settings reflects the selected recipient; note details attributes remote results and maps remote failure codes to retry/settings actions. No feature sends recordings directly: both saved-note jobs and trials use the injected transcription engine boundary.

Pearl foundation: feature reading surfaces are opaque surface/chip with line
hairlines; selected fills and action colours come from the consolidated palette.
The graph minimap and shell navigation use floating Glass. Notes/Add scroll
beneath the shell controls using NavigationInset; Ask/Links keep fixed tools
above the same shared clearance. No data or route topology changes are made.
