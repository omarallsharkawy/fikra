# Native mobile API integration

## Agreed endpoint and scope

The user supplied `https://fikrah-api-23107c84.austriaeast.cloudapp.azure.com/docs` and explicitly requested connecting the mobile client instead of using fixtures. On 27 November 2026, `/health` and `/ready` returned HTTP 200; readiness reported PostgreSQL, Redis and Qdrant ready. This does not prove SMTP, Google configuration, workers or LLM-provider availability.

The [deployed OpenAPI snapshot](deployed-openapi.json) records the supplied deployment: API version 0.1.0, 43 operations including health/readiness. It supersedes the older integration handbook snapshot **for this deployment only**. The server added OTP endpoints and favorites, and changed the password minimum from 15 to 5 characters. No backend source, deployment or public contract is modified by this mobile feature.

## Configuration and runtime

- Default mobile mode: `connected`, calling the supplied HTTPS origin directly. No browser cookies, local web proxy or emulator host forwarding.
- Override the origin with `--dart-define=FIKRA_API_URL=https://<approved-origin>`; values must be HTTPS origins without credentials, path, query or fragment. Redirects are not followed. Normal certificate validation remains enabled.
- `FIKRA_MODE=development` explicitly enables volatile fixtures. `FIKRA_MODE=demo` preserves the legacy local app. No silent fallback to fixtures on network/authentication failure. Legacy preview badges follow the selected Riverpod mode, including test overrides, rather than the build-time default.
- Connected and development use the existing product UI, Riverpod, GoRouter and Inter/Noto Arabic typography. Legacy processing/maintenance is started only in demo mode. Shared appearance preferences do not migrate legacy notes or files.
- Connected screens hide preview disclosures and fixture-login shortcuts. Google remains visibly unavailable until approved platform configuration is supplied. The Google ID-token exchange is implemented in the repository; native Google token acquisition is not configured or invented.

## Authentication and OTP

| Mobile action | API operation |
| --- | --- |
| Register | POST `/v1/auth/register/otp` with email/password |
| Verify email | POST `/v1/auth/verify-email/otp` with email/code |
| Resend verification | POST `/v1/auth/resend-verification/otp` with email |
| Request recovery | POST `/v1/auth/password-reset/otp/request` with email |
| Confirm recovery | POST `/v1/auth/password-reset/otp/confirm` with email/code/new_password |
| Login / Google exchange | POST `/v1/auth/login` or `/v1/auth/google`, then GET `/v1/auth/me` |
| Refresh / logout | POST `/v1/auth/refresh` or `/v1/auth/logout` with refresh_token |

Codes are six ASCII digits; client fields provide numeric input, one-time-code autofill and exact-length submission checks. Passwords use the deployed 5–128 Unicode-code-point bounds and are never trimmed. The server owns code expiry, attempt limits and resend policy; the client respects HTTP 429/Retry-After rather than inventing those policies. Acknowledgments remain generic and do not claim delivery or disclose whether an account exists. Verification and reset return to a separate login; no production action-link/domain registration is needed for these OTP routes.

Access/refresh pairs are stored as one platform-protected record, namespaced by API origin. Startup loads the pair, rotates if expired/near expiry, reads the authoritative account, and falls back to login on failure. A protected-resource 401 joins the session coordinator's single-flight refresh and retries once. A second 401 expires the session. Login, action-code, Google and refresh failures never trigger recursive refresh.

Before a refresh request is sent, the old persisted pair is cleared. The replacement pair is persisted before waiting requests resume. This write-ahead invalidation makes a crash/uncertain response require login instead of replaying a possibly rotated refresh token. Epoch guards and serialized vault operations prevent late refresh/restore responses from resurrecting a signed-out session. Logout clears local private state immediately and attempts server revocation, reporting uncertainty honestly.

## Knowledge journeys

Repositories implement project listing/create/rename/delete; note listing/read/create/update/delete/reprocess and proposal accept/reject/regenerate; semantic search; related-note references and supplied graph edges; conversation listing/create/history/delete and streamed messages; and audio transcription.

- Note creation sends a stable Idempotency-Key, exact original body and selected project. A platform-protected, account/origin-scoped attempt record is written before the request and restored after process restart. Store operations are serialized per account. Reconciliation reuses the same key/body. No generic mutation retry, automatic new key or account-ID body field is added.
- PATCH distinguishes omitted title from explicit null. IDs, null titles, UTC instants, revision/generation, unknown processing states and backend favorite flags are decoded explicitly. Favorite UI/filtering is outside this integration scope; the returned value is preserved without inventing a local rule.
- Existing foreground polling and generation fencing remain; backgrounding/logout pause or clear scoped work. Backend saved content remains separate from refinement proposals.
- Chat POSTs JSON to the SSE route with Bearer authentication. The existing UTF-8/CRLF/multi-line parser feeds typed deltas and final complete payloads. Only complete confirms saved messages and sources. EOF, embedded errors and cancellation retain the existing reconciliation path; no reconnect/repost loop is added. Cancellation closes the native connection even while awaiting headers.
- Audio is streamed as one binary multipart file with the recorder's supported MIME type. No language/project form fields, private paths, provider keys or base64 JSON are sent. Returned text still requires review and explicit note saving. PDFs remain device-local.
- Native connections have a 15-second connection limit and 180-second response/header/read limits; chat also retains its existing three-minute overall UI deadline. Cancellation/timeouts close sockets. These are client resource limits, not server latency promises. JSON responses are bounded to 16 MiB. Validation payloads and credentials are never logged; error messages use status/context and safe field names.

## Remaining coordination

No existing verified live test account or native Google client ID was supplied. Do not create unsolicited real accounts, bypass email verification, infer platform IDs or change backend requirements. Automated tests use synthetic accounts and injected HTTP responses plus a real loopback transport. A separate read-only live smoke check covers TLS, readiness, schema and unauthenticated protection. Live email delivery, a verified-user session, provider-dependent processing/chat/transcription and Android/iOS Google sign-in require user testing/configuration and are not claimed as verified.

The deployment does not expose profile editing, stars/streak/achievements or flexible category contracts. Those previously discussed features still need explicit backend contracts. No fake connected results are substituted.
