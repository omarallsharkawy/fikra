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
