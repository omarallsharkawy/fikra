# Handbook operation coverage

IDs refer to the reviewed backend handbook's endpoint reference. This maps all 37 existing operations to capability/UI scope; it does not assign new HTTP routes or implement transport. Every current executable result is a development fixture unless it is explicitly device-local.

| ID | Capability / journey | Current disposition |
| --- | --- | --- |
| A01 | Register | Account preview → awaiting verification; generic acknowledgment, no tokens/email |
| A02 | Verify email | Explicit action-token preview → separate sign-in |
| A03 | Resend verification | Generic preview; no delivery promise |
| A04 | Password login | Explicit fixture session; real password policy unresolved |
| A05 | Google ID-token exchange | Repository seam prepared; native action unavailable pending approved platform configuration |
| A06 | Request recovery | Generic account recovery preview |
| A07 | Confirm recovery | Preview → clear local session → separate sign-in |
| A08 | Refresh | Single-flight session coordinator seam and rotation/race tests; no real refresh request |
| A09 | Logout | Clear private local state; fixture reports no confirmed server revocation |
| A10 | Current user | Real adapter must bootstrap server-resolved identity in its session grant; fixture identity is synthetic |
| P01 | List projects | Workspace bootstrap and General selection by boolean |
| P02 | Create project | Picker action selects returned identity; uncertain create reconciles the list |
| P03 | Read one project | Intentionally no separate screen request: selection currently uses list-returned objects; later adapter may revalidate as needed |
| P04 | Rename project | Picker action, including General without changing protection |
| P05 | Delete project | Confirmed cascade, protected General, fallback selection |
| N01 | Create note | Composer, stable account/project/payload/key attempt |
| N02 | List notes | Selected-project workspace |
| N03 | Read note | Detail, processing polling and conflict recovery |
| N04 | Update note | Explicit save, presence/null semantics, returned queued generation |
| N05 | Delete note | Confirmed deletion, derived-view/source invalidation |
| N06 | Retry processing | Explicit completed/failed reprocessing; pending request does not add another generation |
| N07 | Regenerate refinement | Explicit completed-note action with reviewed generation |
| N08 | Edit proposal | Intentionally excluded from UI pending product approval |
| N09 | Accept refinement | Permanent-replacement confirmation with reviewed note/generation; restart processing |
| N10 | Reject refinement | Preserve saved content, remove proposal, use returned state |
| K01 | Related notes | Note detail links from repository results |
| K02 | Project graph | Note nodes and supplied edges; local drag/zoom/layout |
| K03 | Search | Selected-project submitted query; fixture matching is explicitly non-semantic |
| V01 | Transcribe recording | Device capture ≤60 seconds → fixture text review → separate explicit note save |
| C01 | List conversations | Selected-project history picker |
| C02 | Create conversation | Explicit new conversation; uncertain creation reloads list |
| C03 | Read conversation | Full history, uncertain-send reconciliation |
| C04 | Delete conversation | Confirmed delete; notes remain |
| C05 | JSON message exchange | Intentionally not selected by current UI; use one streamed exchange per send, never a JSON fallback/replay |
| C06 | Streamed exchange | Provisional delta/final/embedded error/EOF state and pure framing tests; no HTTP connection |
| O01 | Liveness | Deferred diagnostics for real environment setup; no per-screen health dependency |
| O02 | Readiness | Deferred diagnostics for real environment setup; not a feature-readiness guarantee |

Production email routing, Google configuration, real credentials, durable creation-attempt restoration and running-backend/provider acceptance remain integration-phase work. No callback discriminator, pagination, moving, user-defined graph relationships or note history is invented.
