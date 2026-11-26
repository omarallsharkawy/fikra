# Account login and missing recovery email

## Observed behavior

On 27 November 2026, the physical Android device initially reported connection failures without HTTP responses. Later attempts made through the actual Flutter API transport received:

- `POST /v1/auth/login`: HTTP **401**. The user confirmed the current screen says the email or password is incorrect.
- `POST /v1/auth/password-reset/otp/request`: HTTP **202**. The user reports that the six-digit recovery email has not arrived.

The API origin is `https://fikrah-api-23107c84.austriaeast.cloudapp.azure.com`. The mobile request uses JSON fields `email` and `password` for login, and `email` for recovery. It normalizes only the email by trimming and lowercasing; password case, whitespace, and Unicode are preserved. Neither endpoint requires a pre-existing access token. Account addresses, passwords, codes, tokens, and response bodies are excluded from profile diagnostics and this report.

HTTP 202 is the contract's generic acknowledgment, not evidence of account existence or successful mail delivery. No recovery confirmation, verified signup, or authenticated login has yet been observed for this real account. Development preview accounts were fixtures and were not migrated to the deployed backend.

## Backend checks needed

Check the deployed environment privately, using the address entered by the account owner:

1. Confirm whether the account exists in the same database/environment used by this API deployment. Do not expose this distinction through a new public response.
2. Check whether the account has a password hash. The current backend recovery implementation requires both an existing account and a non-null password hash. A Google-only account therefore needs separate product discussion before changing its password setup behavior.
3. Check whether the existing send limit suppressed the request. Keep timing and attempt policies backend-owned.
4. If the account is eligible, trace the `reset_password_otp` outbox delivery: queued, attempted, delivered, deferred, or failed. Check sanitized provider rejection/SMTP errors and sender/provider configuration. Do not share SMTP credentials, raw OTP values, action payloads, or mailbox contents.
5. Verify actual receipt with the account owner, then confirm reset and log in again from the mobile app. A successful password reset must retain the existing session revocation and separate-login behavior.

These are diagnostic checks, not requested backend contract changes. No backend source, account records, mail configuration, or security policy has been changed by the mobile work. A concrete backend defect or required product change must be discussed before implementation.

## Separate connection observation

AdGuard filtering was active during initial connection timeouts. Later successful HTTP responses coincided with a changed device network state. This does not establish which network component caused the original failure. The agent did not disable filtering, change device network policy, bypass TLS verification, or automatically replay authentication requests.


## Account origin confirmed

The account owner confirmed that the credentials were used before API integration. That preview account was not provisioned on the deployed backend by the Flutter fixtures. Using the same email address does not migrate a preview identity or password. The next verification step is real registration through `POST /v1/auth/register/otp`, email-code verification, and separate login. Existing preview data remains isolated as previously agreed; no migration or automatic backend registration is introduced.

This explains why a preview login must not be used as an end-to-end backend login test. It does not establish whether the same email was independently registered elsewhere. Backend mail delivery should be investigated if registration or an eligible verification resend is accepted but the account owner still receives no code.
