# Features

## Overview

One folder per screen group of the FIKRA Flutter app. `lib/app/router.dart` is the only file under `lib/` outside this directory that imports these screens. Features read and write data through the Riverpod providers in `lib/app/providers.dart`.

Shared feature boundaries: `add`, `ask`, `links`, and `notes` use `ProjectHeader` from `projects`; `ask`, `links`, `note_details`, and `notes` use the display helpers in `shared`; `note_details` also uses its external-file opener.

## Subdirectories & Boundaries

- add: [./add/EGM.md](./add/EGM.md) - Composer branch at `/add`, entered by the floating Add button: text, voice recording, and PDF capture, with save-then-analyze ordering.
- ask: [./ask/EGM.md](./ask/EGM.md) - Chat tab at `/ask`: questions answered from the selected project's notes, with sources.
- links: [./links/EGM.md](./links/EGM.md) - Optional graph at `/links/graph`: pure capped layout, moved to an isolate for large projects.
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

## Links library (redesign phase 3)

- connections: [./connections/EGM.md](./connections/EGM.md) owns Browse and Suggestions at `/links`, plus `/links/note/:id`. Its pure cached derivation is shared by both screens.
- links now owns the retained graph at `/links/graph`; the library header opens it. Shared link actions/picker are reused. Note-details rows remain unchanged.

## Ordering & IA (redesign phase 4)

- `settings` groups existing settings into six sections with red Erase all data alone at the bottom.
- `voice_text` orders service/model/language/auto choices first, then `Try it`, then collapsed `For testing`.
- `notes` adds session-scoped Oldest-first sorting (`notesSortProvider`) alongside Newest-first.
- `projects` and `shared/project_picker` order the current project first, then remaining projects by `Project.createdAt` descending.
- Main screen headers label icon actions through `HeaderActionButton` when space and text scale allow; all search fields expose an accessible clear (`X`) button that keeps focus; `note_details` shows a visible `Edit` pill in its header.

Connections previews are ID-validated route extras. Shared project indexes keep per-note adjacency and suggestion lookup out of screen builds; cold reading routes retain opaque loading content.
