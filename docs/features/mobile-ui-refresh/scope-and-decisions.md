# Mobile UI refresh: scope and decisions

Status: supported mobile journeys refreshed; new backend capabilities require the handoff below.

## Reference and confirmed decisions

- Reference: user-supplied `Fikrah - App.html` (SHA-256: `47aa257d0b1524c255d2520897c2fb510218b61289b643495c712cbc689ca2eb`).
- Target: the existing Flutter mobile client. The HTML is a visual and interaction
  reference, not a replacement architecture or an authority for backend behavior.
- User wants the new product features as well as the visual refresh and requested
  that their requirements be agreed before implementation.
- Keep Inter for English/Latin text and the existing NotoSansArabic font.
- Keep FIKRAH branding, default English and Arabic/RTL support.
- Existing legacy local notes/files remain separate; no implicit migration.
- User confirmed mobile-only implementation with explicit development fixtures;
  the user will implement backend changes in the backend chat/repository.
- User selected six-digit verification codes. The backend owns code issuance,
  expiry, attempts, resend and purpose binding. The previously suggested numeric
  limits were not approved and are not requirements.
- User approved flexible, editable categories and backend suggestions that the
  user can override; categories remain separate from extracted concepts/edges.
- User explicitly required documentation of every needed backend change and no
  invented product/backend rules. Streak/achievement formulas are undecided.
- See [backend handoff](backend-handoff.md). Proposed wire field names, routes,
  status codes or policies must not be treated as existing API capabilities.

## Feature inventory

| Area | Reference behavior | Existing mobile/backend contract | Decision needed |
| --- | --- | --- | --- |
| Presentation | Neutral dark/light surfaces, saturated note cards, central blue capture button, new welcome/forms/chat/profile | Flutter shared tokens, Riverpod, GoRouter | Port visual language and retain accessibility/large text |
| Favorites | Toggle a star, filter starred notes | No favorite field/API in current contract | Persistence owner and account/project scope |
| Categories | AI / App dev / Study / Life, editable selection and local keyword guess | Backend concepts and relationships; no user-category field | Flexible categories vs fixed list; no client inference |
| Habit | Daily goal, consecutive-day streak | No habit API | Qualifying event, timezone/day boundaries, deletion and offline behavior |
| Achievements | Five-day streak, twenty links, three voice notes | No achievement API or voice-origin field on saved text notes | Exact thresholds, progress semantics and retention |
| Profile | Name/handle, avatar initials, editable identity | Account provides ID/email/verified only | Profile fields, handle rules and persistence |
| Interests | Optional onboarding interest selection | No preference/personalization API | Whether interests only record preferences or influence processing |
| Reminders | Toggle daily reminder | No scheduling in reference; no mobile reminder implementation | Opt-in, reminder time/timezone, permission and suppression behavior |
| Note editing | Immediate local autosave, deletion with Undo | Explicit PATCH, permanent deletion, revision/proposal conflict handling | Preserve explicit save and deletion semantics unless contract is changed |
| Voice/files | Browser speech recognition, file-name-only attachments | Native capture -> editable transcript -> explicit text save; PDFs local-only | Keep real mobile capture/PDF boundaries; no upload promise |
| Verification | Accept any four digits; local password hash | Email action token; verification does not log in; reset clears session | Retain token flow or coordinate a new backend contract |
| Knowledge/chat | Local keyword guesses create links/answers | Backend-owned concepts, links and grounded chat | Preserve backend authority and uncertainty/reconciliation states |
| Data reset | Reset local demo notes | Private product data and separate legacy local area | No production reset-data action without a defined contract |

## Earlier discussion proposals — NOT approved; do not implement

1. Favorites and profile belong to the authenticated account. Filters, notes and
   categories respect the selected project; unrelated account data never leaks.
2. A daily goal is 1, 3 or 5 successfully created text notes across the account;
   edits, retries of the same idempotent attempt and failed saves do not count.
3. Streak is consecutive account-calendar days meeting that goal, using an
   explicit account timezone. Yesterday's streak remains active until today's
   day ends. A later goal change applies from the next day. Deleting a note
   does not retroactively erase an earned day. These rules need backend support.
4. Achievement targets match the reference: five qualifying days, twenty actual
   backend relationships, and three successfully saved voice-derived text notes.
   Voice provenance needs an explicit contract; the client cannot infer it from
   content. Whether an earned badge stays unlocked needs agreement.
5. Reminders require opt-in, an agreed daily local time, OS permission and
   cancellation on sign-out. Scheduling details and completion suppression are
   not implied by the HTML toggle.
6. Category suggestions may come from the backend; choosing a category does not
   invent a knowledge-graph edge or rewrite extracted concepts.
7. No password policy, public handle, OTP, content synchronization or production
   deployment configuration is invented from the prototype.

## Open decisions

- Backend must confirm the six-digit challenge request/response contract and
  policies; existing token endpoints are not silently repurposed.
- Category endpoint/DTO/validation details require backend implementation.
- Approve or amend habit/achievement rules, including timezone and badge retention.
- Define profile name/handle rules, interest effects, reminder time and permissions.
- Retain explicit note-save/permanent-delete behavior or approve a separate
  autosave/Undo contract. The reference's local Undo is not a backend guarantee.

## Delivery approach

After requirements are approved, split independent product capabilities into
feature branches from updated dev. Each completed feature includes behavioral
regression tests, UI checks in Arabic/English and light/dark, and updated feature
and phase documentation. Use merge-commit PRs to dev. Keep local AGENTS ignored
and preserve existing user documentation moves.

## Implemented presentation and fixes

- Recreated neutral light/dark surfaces, colored cards, abstract welcome shapes,
  centered capture navigation, compact project controls, capture actions,
  selectable graph nodes, message bubbles and a persistent chat composer.
- User requested cleaner, iPhone-like typography after reviewing the first
  version. Retained approved Inter/Noto faces, reduced headings/actions to
  SemiBold, and used Regular reading text with quieter sizes and line heights.
- Refreshed existing profile/settings presentation using available account data.
  No fabricated counts, achievements, categories or working reminder toggle.
- Kept explicit note saving, real graph relationships, local-only PDFs, native
  capture/review and authoritative conversation history/reconciliation.
- Fixed verification returning to sign-in with cleared password, bounded graph
  zoom and fit controls, enlarged graph labels, content direction independent
  of UI locale, and screen-reader activation of navigation/graph controls.
- Kept the development workspace notice concise, with full fixture limitations
  available through its information button. No live API is implied.

Six-digit authentication, stars, categories, profile fields, activity summaries
and reminders are separate backend-dependent capabilities. The handoff records
what the backend needs to define before mobile integrations can be finalized.
The current token-based development verification remains available; it is not
silently converted to the requested code contract.

## Implicit General workspace

The user requested hiding the General project choice until they create a
project, and confirmed that General must remain selectable afterwards to reach
earlier ideas. With no custom projects, the UI shows only a New project action;
the existing General workspace remains selected internally. Creating a custom
project exposes the selector with both General and custom projects. Deleting
the last custom project returns to the implicit General state. No note moves,
new defaulting policy, backend contract or persistence changes are introduced.

## Subsequent UX refinement

Project management has since moved to Settings -> Projects at the user's
explicit request. Main journeys have no project selector or New project control;
they show a read-only scope caption when custom projects exist. General remains
implicit before any custom project and selectable in Settings afterwards. See
[the UX interaction design](../mobile-ux-flow/interaction-design.md) for current
navigation, fixed save actions, preview information and conversation history.
