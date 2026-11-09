# Features

## Overview

One folder per screen group of the FIKRA Flutter app. `lib/app/router.dart` is the only file under `lib/` outside this directory that imports these screens. Features read and write data through the Riverpod providers in `lib/app/providers.dart`.

Dependencies between features are limited to two shared points: `add`, `ask`, `links`, and `notes` use `ProjectHeader` from `projects`; `ask`, `note_details`, and `notes` use the helpers in `shared`.

## Subdirectories & Boundaries

- add: [./add/EGM.md](./add/EGM.md) - Composer tab at `/add`: text, voice recording, and PDF capture, with save-then-analyze ordering.
- ask: [./ask/EGM.md](./ask/EGM.md) - Chat tab at `/ask`: questions answered from the selected project's notes, with sources.
- links: [./links/EGM.md](./links/EGM.md) - Graph tab at `/links`: pure capped layout, moved to an isolate for large projects.
- note_details: [./note_details/EGM.md](./note_details/EGM.md) - Pushed read view and editor at `/note/:id` and `/note/:id/edit`.
- notes: [./notes/EGM.md](./notes/EGM.md) - List tab at `/notes`: day-grouped lazy list with cached client-side search.
- projects: [./projects/EGM.md](./projects/EGM.md) - Shared header, project switcher, name prompt, and the `/welcome` screen.
- settings: [./settings/EGM.md](./settings/EGM.md) - Pushed screen at `/settings`: theme selection and full local data wipe.
- shared: [./shared/EGM.md](./shared/EGM.md) - Pure note display helpers for titles and source icons.
