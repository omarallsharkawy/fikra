# User stories and capability map

No HTTP implementation or connection configuration is introduced in this phase. Names below are feature capabilities, not newly assigned routes. The reviewed backend handbook owns transport details.

| Story | Screen/action | Controller/state | Repository capability | Result and failure handling |
| --- | --- | --- | --- | --- |
| Register | Account / create account | Session awaiting verification | Register | Generic acknowledgment; no tokens; development fixture explicitly labeled |
| Verify/resend | Check email / verify, resend | Verification pending, link error | Verify email, resend verification | Verification returns to login; invalid link retains input; no delivery promise |
| Login/restore | Account / login | Signed out, restoring, authenticated, expired | Login, current user, restore | Bootstrap user then projects; auth failure is separate from access expiry |
| Google | Account / Google | Native identity unavailable/configuration pending | Exchange Google ID token | No substitute access/Firebase token or invented platform IDs |
| Recover | Account / forgot/reset | Recovery request, awaiting reset, login | Request recovery, confirm reset | Generic request; no auto-login; clear private state after reset |
| Logout/account change | Account / sign out | New session epoch | Logout, clear session | Clear all private controllers; distinguish local cleanup from server revocation |
| Select/create/rename | Project picker | Project loading/selected/error | List/create/rename project | General by boolean; stale previous-project loads discarded |
| Delete project | Confirm cascade | Busy/error, fallback General | Delete project | General protected; remove notes/conversations/knowledge caches |
| Create note | Composer / save | Draft, pending attempt, saving | Create note with attempt key | Saved note distinct from processing; same body/project/key on uncertain retry |
| Edit note | Detail / save | Edit draft, saving | Update note with explicit field presence | Returned saved state queues processing; preserve failed input; no assumed optimistic precondition |
| Observe processing | Notes/detail, app resume | Queued/processing/completed/failed/unknown | Read note | Bounded lifecycle-aware polling; no failure fabricated from local wait limit |
| Retry processing | Detail / retry | Busy, returned snapshot | Request processing | No endless automatic retry; saved text remains |
| Review proposal | Detail / accept, reject, regenerate | Saved/proposal separated, conflict review | Refinement action with generation | Acceptance replaces content permanently; conflict reload then deliberate review |
| Delete note | Detail / confirm | Busy, invalidated references | Delete note | Remove graph/search/citations; no undo endpoint |
| Search | Notes / submit query | Query, loading/results/error | Search selected project | Repository result order; empty success; preserve query, reject stale results |
| Related notes | Detail / related | Related loading/results/error | Read note connections | Same-project actual relationships; open current note |
| Graph | Map / zoom, drag, open | Graph loading/empty/error | Read project graph | Every node is a note; only supplied edges; local geometry/gestures |
| Conversations | Ask / new, history, delete | Selected project conversation | List/create/read/delete conversation | Full history, nullable titles; switch project clears selection |
| Send chat | Ask / send | Sending, provisional, confirmed, uncertain | Stream exchange | Final authoritative pair replaces deltas; support true/false/null; no automatic duplicate replay |
| Recover chat | Ask / reload history | Reconciling then reviewed | Read conversation | Reload before allowing deliberate resend after uncertainty |
| Voice | Composer / record, stop, transcribe | Permission, recording ≤60s, review/error | Transcribe recording | Editable text only; separate user save; no automatic note |
| PDF | Composer / select, open local PDF | Local file/error | Device file picker/opener | No upload/extraction/attachment API or cloud durability claim |

Health/readiness are deferred diagnostics for the live-integration phase; no screen requires them. Proposal editing is intentionally excluded pending approval. No pagination, moving, profile editing, account deletion, user-defined links or version history is introduced.
