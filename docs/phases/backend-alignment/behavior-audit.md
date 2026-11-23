# Backend-aligned mobile behavior audit

## Baseline and source

Reviewed 23 November 2026. Mobile integration baseline: `ec7f59e81e2d1190e8b2114f984ed0886fd05664`. Backend `dev`: `4244fd8f3de27175adf9216b25e9a553f3df5e98`; its handbook describes runtime revision `5dc942037b6d5b540ede9a20371ec74f88f16840`.

All seven handbook files were read in order, including the complete OpenAPI snapshot. The requested backend directory does not exist; the actual source is `docs/mobile/`. The user's uncommitted copies under mobile `docs/backend-integration/` are byte-identical to those files. Their addition and three older-document deletions are pre-existing user work and are not included in this change. Backend inspection is read-only. No server or third-party provider is contacted by application flows.

## Complete journey and ownership

Capture → understand → organize → connect → retrieve → discover. Email registration awaits verification, then login establishes a session. Google exchanges an ID token for a FIKRAH session. Session bootstrap resolves the user and projects, restoring an accessible selection or `is_general`. A text draft is saved once with a stable creation attempt. Saving and background processing are separate. Processing supplies a nullable generated title, concepts, and a separate proposal. The user reviews/accepts/rejects/regenerates. Completed knowledge supports project-scoped search, actual note relationships, and project conversations with authoritative final responses. Recording produces reviewed text before a separate save. PDFs remain on-device.

Flutter owns presentation, local drafts, microphone/files, graph geometry, controller transitions, session coordination and stale-response rejection. Backend owns identity verification, authorization, persistence, IDs/timestamps, quotas, generations, processing, concepts, relationships, retrieval and grounded responses.

## Existing implementation

| Area | Existing behavior | Required correction |
| --- | --- | --- |
| State/navigation | Riverpod, GoRouter, persistent five-branch shell; project existence gates welcome | Gate workspace by explicit account/development-session state |
| Identity | No account repository or account-scoped cache; connected mode deliberately unavailable | Explicit signed-out, awaiting verification, recovery, authenticated, expired states; no pretend real authentication |
| Projects | SQLite projects have no `is_general`; user creates first project | Use returned General boolean, default selection, protected deletion and cascade warning |
| Capture | Drift requires title; local source/attachments; client NoteProcessor invokes demo AI | Optional title, text-only capability, stable attempt, queued/processing/completed/failed snapshots |
| Editing | original/edited/proposed text, restore-original and move support | One saved content field, explicit PATCH presence; no move/history/undo promise |
| Refinement | Local rewrite status and optimistic local edits | Separate proposal and expected processing generation; reload/review on conflict |
| Search | Local Arabic substring/token filtering | Repository-scoped search; fixture matching explicitly non-semantic |
| Graph | Local user links, suggestions and group/cluster nodes | Note nodes and supplied edges only; layout stays client-owned |
| Chat | One flat chat per project, user row saved before AI, `found` bool | Conversations/history, tri-state support, provisional deltas replaced by final pair; uncertainty and reconciliation |
| Voice | Existing record/permission seams, local Whisper and optional third-party services, automatic saved-note transcription | Dedicated 60-second capture → repository transcription → editable draft → explicit save; no provider calls in this phase |
| PDFs | Existing on-device attachment storage/viewer | Local selection/opening only; no implied upload or extraction |
| Validation | Extensive existing widget/repository tests | Preserve legacy regression suite; add contract-focused controller and widget coverage |

## Priority and approved technical approach

1. Typed capability interfaces, failures, account/session state and account epoch fencing.
2. Default development journey composition using existing Riverpod, GoRouter, theme and floating navigation. Keep the old local-first demo available explicitly; never migrate or erase it.
3. Project/text capture/processing/refinement behavior.
4. Search/graph/conversation behavior and uncertainty recovery.
5. Native recording and local PDF presentation, lifecycle/account isolation, regression validation.

The user explicitly approved separating the new default product journey from the legacy demo and keeping existing local data separate without migration. No dependency replacement or live transport is required. Fixtures are isolated in the development data package; product widgets depend on controllers and capabilities, never fixture collections. Fixture state is volatile and labeled throughout.

## Requirement decisions intentionally unresolved

Password policy (current schema 15–128 versus earlier minimum five), production email routing/purpose ambiguity, Google audience/platform identifiers, proposal editing, supported-language quality/mixed language behavior, long-note provider constraints, collection pagination/graph scale, offline sync and history. Do not invent values or expose an unapproved proposal editor. Registration/reset/Google production actions report unavailable until configured. Development account/story scenarios are explicitly synthetic.
