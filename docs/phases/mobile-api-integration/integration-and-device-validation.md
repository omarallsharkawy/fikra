# API integration delivery

## Phase 1 — Contract audit

Use the supplied deployment OpenAPI and compare it with the earlier integration handbook. Adopt the deployed OTP routes and 5–128 password bounds. Preserve JSON/Bearer, Google ID-token exchange, note idempotency, polling, generation checks, and authoritative SSE completion. Keep backend implementation and platform identifiers outside this mobile change.

## Phase 2 — Native repositories and presentation

Implement the native transport, typed repositories, protected session/attempt storage, and connected-mode wiring. Keep explicit development fixtures and legacy local data isolated. Replace preview-only connected labels and tokens with the real six-digit flows. Present account errors above the form, preserve entered values, dismiss the keyboard on submission, and maintain consistent authentication spacing. Respect the content's writing direction in note headings and live editors while retaining explicit LTR account fields, the English interface default, Inter, and the existing Arabic font.

## Phase 3 — Verification and delivery

Run contract, controller, connected-interface, localization, accessibility, and product regressions. Run read-only live TLS/connectivity checks. Build an ARM64 profile APK using two CPU cores, one Gradle worker, and a 1 GiB heap. Validate the actual account journey on the physical device. Publish the completed feature branch, open its PR through the browser, and merge into `dev` with a merge commit after checks pass.

## Verified physical-device results — 27 November 2026

The owner initially tried credentials from the pre-API development preview. Those identities and passwords had never been provisioned by the Flutter fixtures on the deployed backend. The owner then completed the following on the connected Xiaomi phone:

| Operation | Observed response |
| --- | --- |
| Real registration, `/v1/auth/register/otp` | 202 |
| Six-digit mailbox verification, `/v1/auth/verify-email/otp` | 200 |
| Separate password login, `/v1/auth/login` | 200 |
| Account lookup, `/v1/auth/me` | 200 |
| Owner-created note | Saved content and completed backend processing visible in the actual detail screen |

The owner also exercised real voice transcription and reported the stale voice-review UI described below. The agent did not request or read the owner's password or OTP, create an account on their behalf, or publish their account/note contents. The original preview workspace remains separate. The repaired authentication APK was installed manually after Android refused USB installation; its copied checksum matched the built artifact. No app data was cleared.

The earlier recovery request received a generic 202 while the owner was using preview credentials, and no recovery email arrived. This does not establish a mail-delivery defect for an eligible real account. Live password-reset confirmation has not been exercised; conditional backend checks remain documented in `docs/features/mobile-api-integration/backend-authentication-triage.md`.

## Connection diagnosis and limitations

Some device requests failed at the connection stage after approximately 15 seconds, without an HTTP response; later manual attempts succeeded quickly. Android reported no UID network-policy restriction. Public health requests under the app's own UID succeeded, but curl is not the Dart transport. AdGuard filtering was active initially; later network state changed to cellular without the previous Wi-Fi/VPN indicators. The evidence does not isolate the cause of intermittent connectivity. The agent did not disable filtering, change network policy, bypass TLS verification, or automatically replay authentication requests.

Debug/profile diagnostics contain only fixed authentication route names and status/category values. Bodies, headers, account addresses, token values, codes, passwords, and exception text are excluded. Release builds do not emit these diagnostics. Temporary socket-metadata profiling was used without HTTP-body profiling, then its debugging connection was removed.

## Voice-review regression

The owner found that a saved voice note left its audio/transcript review visible when opening the next idea. The save handler now clears capture state only after the workspace confirms a saved result, and a new draft gets a fresh composer scroll/view state. Native cleanup is serialized before the next recording; late voice results are ignored. Uncertain/failed saves preserve all review input and the stable creation key. Separate local documents are retained. Regression tests cover both English/Arabic success and lost-response reconciliation, a new blank composer, late transcription, and account-boundary document cleanup.

## Automated verification

The final full regression run passed **172 tests** with one opt-in live smoke test skipped by default. Static analysis reported no issues.

The product regression suite covers connected English/Arabic journeys at 360dp and 1x/2x text, account errors and keyboard behavior, RTL headings/live editing, exact password preservation, secure session restoration/rotation, account isolation, idempotent creation attempts, note polling/refinement, multipart upload, graph/search, and SSE finality/cancellation. Test accounts and HTTP responses are synthetic; actual native loopback tests exercise transport bytes and redirect refusal.

The opt-in read-only live smoke test separately passed HTTPS certificate validation, health/readiness, deployed six-digit/five-character schema constraints, and the unauthenticated account route's 401. It creates no account, sends no email, and performs no AI operation. The owner performed the real account/note validation above.

Native Google sign-in still needs approved platform configuration. Live chat, password-reset confirmation, and restoration after killing the phone process remain outside the manually verified results. Automated tests cover these adapters and session/storage behavior where applicable. Backend source/deployment, platform identifiers, legacy data, local AGENTS.md, and the owner's unrelated documentation moves are excluded from this change.
