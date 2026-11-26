# API integration delivery

## Phase 1 — Contract audit

Read the supplied deployment OpenAPI and compare it to the existing integration handbook. Adopt the deployed OTP routes and 5–128 password bounds; preserve JSON/Bearer, idempotency, note polling, proposal generation and SSE completion contracts. Keep all backend work outside this mobile change.

## Phase 2 — Native repositories and state

Implement the native transport, typed repositories, protected session/attempt storage and connected-mode dependency wiring. Replace preview-only labels/shortcuts in connected UI. Preserve explicit development fixtures and isolated legacy mode. Test authentication/refresh/account boundaries and uncertain writes before device delivery.

## Phase 3 — Validation and delivery

Run relevant controller, contract, connected-interface, localization/accessibility and product regressions. Perform read-only live TLS/connectivity checks. Build an ARM64 profile APK with two CPU cores, one Gradle worker and 1 GiB heap, then install on the physical phone without clearing app data. Publish the completed feature branch and merge its PR into dev using a merge commit after checks pass.

## Verified results — 27 November 2026

- 158 relevant automated tests pass; the live smoke test is skipped by default and passed separately with `FIKRA_LIVE_SMOKE=1`.
- Nineteen transport/repository/session/storage cases cover OTP payloads, native multipart bytes, redirects, safe error mapping, DTOs, PATCH presence, stable note keys, shared refresh, restart restoration, revoked/uncertain refresh, logout races, cleanup failures and SSE finality/cancellation. Existing controller regressions remain passing.
- Four connected UI journeys at 360 x 800 dp cover English/Arabic and 1x/2x text through registration, incorrect/correct code, recovery, separate login, note save/poll/search, graph, streamed chat sources and logout. These use real API adapters with injected synthetic HTTP responses; they are not live-account tests.
- Live read-only checks through the native Dart transport passed normal HTTPS certificate validation, `/health`, dependency readiness, deployed six-digit/five-character schema constraints and the account route's unauthenticated 401. No account, email or provider-funded operation was invoked by these checks.
- Static analysis reports no issues; diff whitespace checks pass.
- ARM64 profile APK built successfully (129.8 MB, Gradle assembly 103.6 seconds) using two CPU cores, one Gradle worker and 1 GiB heap. Installed with `adb install -r` on the connected Xiaomi M2010J19SG; cold launch returned Status ok. No app data was cleared.
- The connected sign-in screen was visually checked on the awake physical phone with the email keyboard open. Fixture disclosures/shortcuts are absent. The user was asked to exercise account/email-code login themselves; a verified live-user session and provider-dependent features are not claimed as tested until that result is available.
- Backend source/deployment, platform identifiers, Google registration and legacy local data were not changed. Local AGENTS.md and the user's unrelated backend-documentation moves are excluded.


## Authentication failure follow-up

The user reported failures in both login and registration after the first connected APK. Do not treat the successful scripted journeys as proof that a real account can sign in, and do not merge until the real failure is understood.

The phone process remained alive and the inspected Android runtime/Flutter error logs contained no crash. Public health and deliberately invalid authentication requests were checked from the physical Android device without creating accounts or sending email: health returned 200, an incorrect reserved-example login returned 401, and malformed registration email returned 422. HTTP/1.1 with the Dart user agent also returned the expected 401. These checks establish reachability only; they do not validate the user's credentials, email delivery, or a complete account journey.

Account failures now appear in a live-region panel above the fields and scroll into view, preserve entered input, and distinguish connection, timeout, TLS, server availability, and rejected credentials. Submitting dismisses the keyboard. Auth headings, icon sizes, and spacing are consistent across login, signup, verification, and reset. Profile/debug builds emit only fixed auth route names and status/category diagnostics; bodies, headers, token values, email addresses, exception text, and passwords are excluded. Release builds do not emit these diagnostics. No server contracts, account data, or backend source were changed.

Validation: 163 offline regression tests passed (one opt-in live smoke test skipped), including new English/Arabic login/signup failure journeys at 360dp and 1x/2x text scaling. The analyzer reported no issues. Real-font failure screenshots were reviewed. A new physical-device attempt is still required to classify the original report.
