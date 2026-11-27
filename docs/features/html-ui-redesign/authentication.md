# Authentication presentation

The HTML's landing, sign-up and login layouts use the original 16dp gutter, 68dp header, 14dp vertical rhythm, 56dp illustration tile, 52dp fields and 48dp actions. The landing steps highlight sequentially over three seconds and become still when the platform requests reduced motion. Arabic mirrors navigation and layout, while each entered name detects its own script and email/password/code fields retain left-to-right direction. The original API error mapping remains localized and never renders server response bodies.

Registration now requires a trimmed name of at most 40 grapheme clusters, a valid email and the existing 5–128-character password policy. The first field uses given-name autofill. Password strength is an advisory indicator, not a replacement for server validation. Only email and password are sent to the existing OTP registration endpoint. After successful registration, the name is saved in device storage under the normalized address and claimed by the verified account on subsequent login. Storage is namespaced by API origin and account. Local state is isolated across account boundaries; profile editing and the one-time missing-name prompt are completed with Home/Me.

Verification and password recovery use the existing six-digit server OTP flows, including resending, mapped failures and server-directed rate limits. The HTML only simulates recovery with a checkmark; the client retains the real multi-stage journey and uses the new shared layout. Verification/reset success returns to a separate login. Inputs survive errors and clear secrets when switching journeys. Unconfigured Google sign-in and raw local-revocation notices have been removed from the visible connected UI. Explicit development-only fixture entry remains separate from the production API runtime.

## Validation

- `test/product/auth_layout_test.dart`: all stages at 360dp, Arabic/English, light/dark, 1x/2x text, keyboard visibility, focus order and secret clearing.
- `test/product/auth_failure_journey_test.dart`: connection/credential failures preserve inputs and remain visible without exposing private transport details.
- `test/product/connected_journeys_test.dart`: unchanged JSON/OTP/Bearer contracts through the actual client adapters with test-only transport responses; also checks name handoff to the account.
- `test/product/redesign_auth_test.dart` and `local_profile_test.dart`: name-first validation, Unicode limits, direction, unchanged registration payload and storage isolation.
- `test/screenshots/html_redesign_test.dart`: captures the real Flutter widget tree against synthetic repository data, never production fallback data. Matching reference captures were taken from the unmodified HTML in the browser.

The physical Android build containing the approved navigation and tokens (`b79a4ce`) installed successfully over the existing application. The device APK SHA-256 matched the generated artifact (`e893514abfccb49d1b2b025c332221679a11972ad66eeeafc5328111276cb7dd`). The device was on its signed-out landing screen, so authenticated navigation on that device still needs a signed-in check. This build preceded the authentication layout changes described above.
