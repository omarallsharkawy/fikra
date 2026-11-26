# Mobile UX flow refactor

## Approved scope

The user approved a full journey refactor: clear authentication headings with
preview explanations in a help surface; a fixed explicit Save action with voice
and PDFs as secondary capture tools; search/ideas ahead of compact project
management; a larger map; and message-focused chat with separate conversation
history. Keep all backend contracts and existing explicit save/review semantics.
General remains implicit until custom projects exist and selectable afterwards.
Keep Inter/Noto, English default, RTL, large text and isolated legacy storage.

## Implementation boundaries

This is a Flutter presentation/navigation change. No production OTP, stars,
categories, activity calculations, sync or notification behavior is introduced.
No controller/repository contract should change. Keep loading/failure/retry,
idempotent save reconciliation, authoritative chat history and destructive
confirmations reachable. Selected project and current conversation remain clear.

## Technical choices

Use the shared ProductScaffold for fixed headers, optional pinned tools and
footer actions. Put detailed development explanations in the preview information
dialog while retaining a visible temporary-data label. Use modal lists for
project management and conversation history. These are presentation-only
surfaces over existing controllers. Respect reduced motion and platform text
scaling; avoid a new package or an additional IDE/emulator process.

## Project-management follow-up

The user explicitly requested moving the project selector/management shown in
their screenshot to Settings. The protected `/settings/projects` page owns
create, select, rename and confirmed deletion. Main journeys show only a
read-only current-project caption when custom projects exist, preserving scope
awareness without a selector. No workspace, draft or existing General data is
moved or removed. Failed operations remain visible on the relevant screen.
