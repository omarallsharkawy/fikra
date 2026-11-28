# Backend changes needed by the new mobile design

## Status and ownership

This is a handoff/request for backend work, not a deployed API specification.
The user owns backend implementation. This chat changes only Flutter, mobile
integration documentation and explicitly labelled development fixtures. Do not
implement local production business rules to fill missing backend capabilities.
No backend source, existing OpenAPI or deployed endpoint is changed here.

Confirmed: six-digit verification codes; flexible user-editable categories with
backend suggestions the user can override; backend ownership of persistence,
streak/achievement computation, profile and goals. English Inter/Arabic Noto and
FIKRAH branding remain mobile presentation decisions.

The HTML is a prototype: local password hashes, accepting arbitrary codes,
keyword-created links/answers, fixed streak thresholds, autosave and local Undo
are not approved backend behavior. Existing JSON/Bearer, Google ID-token,
processing/polling, note-creation idempotency and account isolation contracts
remain in force until a reviewed replacement exists.

## 1. Six-digit email challenges

Mobile needs separate registration-verification and password-recovery flows.
Please provide the final routes, DTOs, error/status mappings and capabilities
before a real transport is wired. The current token methods are not code methods.

Required semantics to specify:

- How to request/identify a challenge, including its purpose and destination.
- Code is six decimal digits; leading zeroes must survive string transport.
- Backend validates the code and binds it to the intended account/purpose.
- Backend owns lifetime, allowed attempts, resend timing, rate limits, code
  replacement/invalidation, one-use behavior and recovery proof.
- Return authoritative challenge/cooldown/expiry/remaining-attempt metadata where
  mobile should render it. Mobile does not assume 10 minutes, five attempts or
  60 seconds; those earlier suggestions were not approved.
- Define generic acknowledgments/account-enumeration behavior and the difference
  between invalid, expired, exhausted, superseded, rate-limited and unavailable.
- Define recovery completion: does verification return a short-lived reset grant,
  or does the final reset submit challenge+code+new password atomically? Avoid
  a mobile-only validation flag being accepted as reset authorization.
- Preserve verification returning to sign-in, rather than manufacturing a
  session. Confirm session invalidation after password reset and sign-in policy.
- Decide how existing emailed token links coexist/migrate. Production app links,
  domains and identifiers are still unresolved; do not invent them in mobile.
- Preserve policy/validation from backend; password length/strength is not
  inferred from the reference's eight-character rule.

Acceptance: valid/invalid/leading-zero/expired/replayed/superseded codes; wrong
purpose/challenge; resend cooldown and limits; uncertain request outcomes;
background/resume expiry; generic recovery responses; no accidental login.

## 2. Stars and note filters

Mobile needs an account-authorized boolean favorite state for a saved note and
an explicit operation to set it to true/false (not an ambiguous toggle replay).
Return authoritative state and define concurrency/revision behavior. Include the
state in note list/detail/search results or provide a coherent metadata read.
Define starred filtering within the selected project without relying on partial
client collection loading. Deleting a note must remove its favorite metadata.

Required backend decisions: DTO/operation names, paging/order, conflict handling,
error mapping and whether existing note revision changes when metadata changes.
Idempotent retries must not invert a star twice. Cross-account access must fail.

## 3. Flexible user categories

Mobile needs category list/create/rename/delete and assignment/unassignment on
notes, plus the selected note's current category and an optional backend-provided
suggestion. A user override must be distinguishable from a suggestion so a later
processing run cannot silently replace a deliberate choice.

Categories are not extracted concepts, projects or graph edges. No keyword guess
or category proximity creates a relationship. Existing General protection and
project deletion semantics remain intact.

Required backend decisions: account vs project ownership; one vs multiple
categories per note; name/length/uniqueness rules; color identifiers; ordering;
category deletion behavior; suggestion acceptance/override/reset; revision and
processing behavior. These are not settled by the UI prototype. Until decided,
fixtures illustrate UI states only and are not a real API contract.

Acceptance: create/rename/assign/unassign/delete, empty results, duplicate names,
unauthorized access, stale assignment and processing-after-user-override.

## 4. Profile, interests and goals

Mobile needs an authenticated profile read/update surface for the name and
handle displayed by the reference, plus interest selection and daily-goal
options. Please define optional/null/default values, validation, uniqueness and
visibility. The reference's editable handle does not establish a public profile,
public lookup or social feature. Avatar initials may be rendered locally from
returned display text; image upload is not implied.

Required decisions: whether name/handle are required; allowed format and rename
rules; interest catalog vs free text; whether interests affect backend processing
or only store preferences; allowed goal values and effective date; onboarding
completion/skip persistence. Never claim personalized AI without backend support.

## 5. Activity summary and achievements

Mobile needs a backend-computed overview containing the displayed streak,
daily-goal progress, idea/link totals and achievement progress/unlock state.
An achievement can include backend-defined title, target, progress and unlock
status; mobile must not hardcode threshold math from the prototype.

Unresolved product rules to decide in the backend work:

- Qualifying event: successful create, processed note, or another event?
- One note/day versus reaching the selected goal to qualify for streak.
- Account/project scope, authoritative timezone and calendar/day boundaries.
- Current-day grace, timezone changes, goal changes and backdated/offline events.
- Idempotent create retries, edits, reprocessing and deletions.
- Exact achievement definitions/thresholds, historical count vs current count,
  permanence of unlocks and recalculation behavior.
- Voice provenance: saved notes are currently text. If a voice-note achievement
  is retained, define trustworthy capture provenance without guessing from text
  or changing a pending create attempt's payload on retry.
- Link count must come from actual backend relationships, not visual proximity
  or invented client inference. Define unique relationship counting/scope.

Fixtures can supply labelled example summaries. They do not calculate or assert
production achievement rules. Missing summaries should be represented as
unavailable, not fabricated zero activity.

## 6. Reminder settings

Mobile owns OS permission and device scheduling; backend owns any synchronized
preference/account summary it exposes. Please decide whether reminder preference
is device-local or synchronized before implementation. Define default off/on,
time selection, timezone changes, completion suppression and logout/account
switch behavior. The HTML toggle does not schedule a real notification.

A fixture toggle cannot be presented as a working scheduled reminder. No native
permission prompt should occur before a deliberate user action. Platform
notification integration is separate from backend delivery/push; neither is
promised by this document.

## 7. Preserve existing note/knowledge contracts

- Keep explicit note save/PATCH, status polling and generation-aware proposals.
  Autosave needs a separate concurrency/failure/draft contract before enabling.
- Keep permanent deletion confirmation. Undo needs a backend-supported restore
  window or delayed deletion contract; a local list reinsertion is insufficient.
- Preserve native voice -> editable transcript -> explicit text save. PDF files
  remain local-only; file upload/extraction/indexing requires an explicit API.
- Preserve project-scoped search, source references, isolated notes on the map
  and backend-supplied relationships. No local answer/classification engine.
- Do not introduce a production reset-all-data control from the demo prototype.

## Response requested from backend work

For each approved capability, return its OpenAPI/DTO revision, route/method,
authorization scope, validation/nullability, status/error mapping, concurrency
and idempotency behavior, and representative success/empty/error examples.
Identify unresolved requirements explicitly. Mobile can then replace the fixture
adapter without importing browser sessions/proxies or implementing backend rules.
