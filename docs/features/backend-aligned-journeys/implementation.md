# Backend-aligned product journeys

## Scope and composition

The default build now opens the backend-aligned **development** journey. It uses the existing Riverpod composition, GoRouter, shared FIKRAH theme, floating navigation, motion, and Arabic/English localization catalogs. It does not contact a backend or third-party provider. `FIKRA_MODE=connected` remains unavailable and fails before app startup.

The user approved a separate product domain and preserving the local-first implementation without migration. Run `flutter run --dart-define=FIKRA_MODE=demo` to open that legacy local app. Its Drift schema, notes, attachments, settings, custom transcription destinations and keys remain unchanged. Default development mode reads appearance/language preferences only; it does not start legacy analysis, transcription recovery or orphan sweeping. It does not import legacy notes into a fixture account. Changing modes is a build choice, not an account migration or a live connection toggle.

## Architecture

- `lib/data/product/models.dart` defines capability values independently of Drift rows: General's boolean, nullable titles, saved content versus proposal, processing generation/revision, field presence for PATCH, graph note nodes, conversations, tri-state support and typed failures.
- `repositories.dart` defines auth, knowledge, protected session storage and pending-attempt boundaries. There are no assigned HTTP paths, base URLs or credentials in the new composition.
- `development/` contains the isolated, volatile implementations. Product screens receive controllers; they do not read fixture maps or instantiate fixture repositories.
- `SessionController` represents restoring, signed out, awaiting verification, authenticated, expired and recovery stages. Registration/verification/reset do not create a session. The future protected-request seam coordinates one refresh and replaces the pair before releasing waiters. Uncertain refresh expires the local session instead of replaying a possibly rotated token. Epoch checks reject late results after logout.
- `SecureSessionVault` stores a real token pair in one protected record when a future real auth adapter supplies it. Development sessions never manufacture or store real tokens; the development composition uses a memory vault.
- `WorkspaceController` coordinates projects, drafts, stable creation attempts, note edits, bounded foreground polling, refinements, search and graph loading. Account/project/request checks discard stale work; proposal conflicts reload and require review.
- `ConversationController` owns conversation selection/history and serializes sends. Deltas are provisional. A complete event replaces the preview with the authoritative pair and merges by message IDs. EOF/error/interruption keeps the draft and blocks another send until history is reloaded. Reconciliation never automatically resends.
- `CaptureController` owns microphone state, the 60-second deadline, lifecycle stopping, transcription review and local PDF selection. The native adapter reuses the installed record, permission and file-opening libraries. No dependency was replaced.
- `ProductRuntime` clears private controllers synchronously when account identity changes, rejects late session work, switches project-scoped chat and invalidates deleted source references. `ProductBoundary` replaces private route widget state on account/session boundaries.
- `chat_frames.dart` is a pure UTF-8/SSE framing utility, tested without HTTP. Mapping validated wire DTOs to feature events belongs to the later transport adapter.

Account and transcription actions honor a returned Retry-After cooldown without discarding credentials/drafts or the recording. Local recording replacement cannot reset an account-scoped transcription cooldown. A transcription authorization failure uses the shared session-expiry path.

Widgets own layout and editable-field presentation. Repositories own data access; controllers own feature orchestration. Graph positions are presentation-only, and every displayed edge comes from the repository. Appearance/language reuse the existing preference repository. Legacy local models remain isolated instead of forcing incompatible server semantics into their schema.

## Corrected behavior

### Accounts and projects

The account screen explicitly labels development previews. Register/resend/recovery use generic acknowledgments and never claim email delivery. Verification returns to sign-in; recovery confirmation clears the session. Google remains visibly unavailable until approved native configuration exists. No domain, scheme, action discriminator or OAuth identifier is invented.

Workspace bootstrap requires an authenticated/development identity and a project marked `isGeneral`. Names are display values, so renaming General preserves protection. Creating a project selects its returned identity. Project deletion requires confirmation, explains the note/conversation/relationship cascade, and returns to General. There is no note-moving action.

### Notes and proposals

Title is optional. Saving returns the saved note and its actual status; it does not wait for processing. One creation attempt snapshots account, project, content/title and key. An uncertain retry reuses that exact snapshot; the draft cannot silently change its body or destination. Known validation/size/deleted-attempt failures can be explicitly reviewed before the user starts a new intentional save. No key is silently replaced to bypass a conflict or quota.

Queued/processing/completed/failed/unknown states are distinct. Creation date, weekday and time come from the stored timestamp converted to local time. PATCH preserves omitted versus explicit-null title. Saved content is not an immutable original: accepting a proposal permanently replaces it, clears the proposal and restarts processing. There is no restore-original or undo promise. Proposal editing remains excluded.

Foreground polling is controller-owned, at most one sequence per selected account/project, with increasing intervals and a finite wait budget. Backgrounding cancels scheduled polling; resume reloads current state. A local wait budget says “still processing,” never changes the note to failed. A processing failure retains content and exposes explicit retry. Poll errors stop the sequence until a user reload; there is no uncontrolled retry loop.

Proposal actions use the last returned generation. A conflict reloads the current note without replaying the mutation. Search/graph/related caches are invalidated after note changes; deleted citations are removed from displayed history without rewriting message text.

### Search, map and conversations

Search is submitted for the selected project, preserves the query on failure and keeps repository result order. Search failure is distinct from an empty successful result. No pagination or cross-project search is implied. The map shows individual completed-note nodes, including isolated notes, and supplied relationships only. Dragging, zoom and geometry cannot create links.

Ask exposes separate project conversations, nullable/automatic titles, full history, explicit new/delete actions and final source references. `supported: false` is a completed unsupported answer; `null` is an ordinary social/identity response without an unsupported badge. Uncertain chat never falls back to a second JSON send. The current draft remains available after history reconciliation for a deliberate user decision.

### Voice and PDFs

Recording automatically stops at 60 seconds, also stops when the app backgrounds, and handles permission/start/stop failures without sending empty audio. Transcription yields editable text; “Use this text in the draft” and “Save text note” are separate actions. A new recording or explicit discard cleans the previous temporary recording. A failed transcript retains the clip for a deliberate retry.

PDF selection/opening is local and labeled accordingly. PDFs are not uploaded, extracted, indexed or associated with backend notes. There is no new attachment contract or silent extraction.

## Development fixtures and limitations

- `reader@example.invalid` opens two synthetic completed notes in a General project with one explicitly seeded relationship. `other@example.invalid` starts with a separate empty General project. Shortcut buttons make the fixture origin explicit. Form preview password: `fixture-only`; the unverified scenario uses `unverified@example.invalid`.
- Registration, resend and recovery acknowledgments do not store passwords or send email. `fixture-verify` and `fixture-reset` preview action states only; they are not wire-format/expiry test tokens or real email links.
- Creation returns queued; subsequent fixture note reads advance through processing to a fixed, clearly identified fixture result. There is no client-side concept extraction, model call or content-based relationship inference.
- Development search is literal substring matching and explicitly labeled as non-semantic. It is not evidence of retrieval quality.
- The default chat script emits a provisional preview, then a different fixed social response with `supported: null`. It deliberately has no mobile phrase classifier. Focused tests supply supported/unsupported/zero-delta/error/EOF scripts.
- Transcription returns fixed review text and explicitly says no audio was uploaded or transcribed. Native recording can still be exercised locally.
- Fixture projects, notes, drafts, conversations and attempt records exist in memory only and reset with the process or sign-out. They do not promise durable saving, offline synchronization or backend processing. Actual durable, account-scoped attempt restoration must be wired with the real repository.

See [operation coverage](operation-coverage.md) for the disposition of all 37 handbook operations.

## Remaining decisions

The backend handbook's unresolved requirements remain unresolved: password policy and short-password login compatibility; email-action routing and cold-start purpose ambiguity; Google registrations/audience/signing IDs; proposal editing; supported/mixed languages; large-note provider limits and coverage; unpaginated collection/history/graph scale. No production URL, release app link, provider credential, universal language support, undo or sync guarantee is supplied by this refactor.

## Real-backend connection checklist

1. Obtain approved reachable origin, deployed contract revision, native Google settings and email-action routing. Confirm the reviewed 37-operation handbook against that deployment.
2. Supply real auth/knowledge adapters at the existing providers, retaining feature controllers. Use JSON/Bearer tokens, Google **ID**-token exchange, documented multipart and POST SSE. No browser cookies/proxy.
3. Wire the protected vault, validated current-user bootstrap, session expiry, single-flight refresh and route-specific errors. Keep passwords/tokens/private payloads out of logs.
4. Implement durable account-scoped attempt storage before enabling real create/restart recovery. Preserve exact key/project/payload on uncertain replays and explicit missing/null PATCH fields.
5. Set transport cancellation/deadlines deliberately; validate SSE DTOs and map embedded errors/EOF to uncertainty. History reload precedes any deliberate retry.
6. Replace scripted note snapshots, literal search, fixed transcript and chat events with returned backend results. Do not add local processing/relationship rules.
7. Run real-device email/Google/session/processing/idempotency/cascade/quota/audio/streaming acceptance using dedicated test accounts, then provider-backed retrieval tests. Fixture checks are not end-to-end backend verification.
8. Resolve release decisions and validate app links/platform identifiers before enabling production connected mode. Preserve or explicitly design migration of legacy data separately.

## Manual walkthrough

1. Run `flutter run` (or build the profile APK). Confirm the development banner on the sign-in screen.
2. Choose “Preview sample workspace.” Verify General, the two fixture notes and their creation weekday/date/time. Rename General and confirm its delete action stays absent.
3. Create a custom project; capture text without a title. Save, observe queued/processing/completed separately, open the note and review saved content versus proposal.
4. Reject a proposal, request another, then accept after the permanent-replacement confirmation. Edit content/title and observe reprocessing. There is no move or restore-original action.
5. Search literal fixture content inside a project, then open Map. Drag/zoom note nodes; new notes do not acquire edges from proximity.
6. Open Ask, create a conversation and send text. Observe the provisional preview being replaced by the scripted final reply. Reopen its history; delete the conversation independently of notes.
7. Record voice; stop manually or wait 60 seconds. Preview transcription, edit it, transfer it to the draft and explicitly save. Select/open a local PDF and confirm it is not uploaded or converted.
8. Sign out, then open the separate empty fixture account. Previous notes, chat, drafts, recordings and selected project must not appear.
9. Build/run `FIKRA_MODE=demo` separately to inspect existing local data. No automatic import or cleanup is performed by development mode.

See the phase validation record for executed checks and limits.
