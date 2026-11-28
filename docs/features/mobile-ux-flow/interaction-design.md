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

## Delivered interaction changes

- Headers stay visible while reading/typing. The temporary-data indicator is a
  compact information action; full fixture/search/auth limits remain readable
  in its dialog rather than being repeated before content.
- Capture and note editing have fixed explicit save actions. Capture disables
  an empty new save while retaining unresolved-attempt reconciliation. Voice
  review/discard remains explicit; local PDF boundaries are visible and detailed
  capture help is expandable.
- Home starts with search and idea cards. Project selection/creation/rename and
  confirmed deletion live only under Settings -> Projects; main screens retain
  read-only project context. General behavior and per-project draft ownership
  are unchanged.
- The graph fills the available content viewport rather than a fixed 420dp box.
  Graph edges, drag/select, bounded zoom and related-note navigation are unchanged.
- Ask shows messages and a growing multiline composer. History is a protected
  `/conversations` page with current selection, reload, explicit create/open and
  confirmed deletion. Opening the list alone preserves the unsent draft; choosing
  a conversation retains the controller's existing history/reconciliation rules.
- Account forms use stage-specific headings. Developer explanations move into
  preview information. Reset success returns to sign-in and clears password/token
  input; it does not create a session. Profile prioritizes Settings before logout.

No backend implementation, token/OTP schema, persistence policy or business
formula changed. Unsupported six-digit authentication and other new features
remain covered by the existing backend handoff.
