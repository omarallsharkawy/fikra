# Google platform configuration

On 28 November 2026 the owner confirmed Web application client ID
`109535867594-0gok833v4j10mtedhee5146g8r8dcgtn.apps.googleusercontent.com`.
The matching downloaded Google client configuration identifies it as a Web
client. It is a public identifier, not a client secret. Its local backend configuration matches. On 28 November 2026 the owner completed native Google sign-in on the physical Android profile app; the deployed Google exchange and subsequent `/me` returned HTTP 200. Use it as the Android plugin's
`serverClientId` (override with `FIKRA_GOOGLE_SERVER_CLIENT_ID` when building
against a different environment). No client secret belongs in the app.

The physical-device profile application ID is `com.fikra.app.stress`; the debug
signing SHA-1 is `5E:13:1A:11:45:AD:42:3A:E4:E8:E1:C8:A8:6C:0B:A1:9B:69:FF:56`.
Google Cloud must have a separate **Android** OAuth registration matching both
values in the same project. The base `com.fikra.app` and its eventual release
signing key each need a matching Android registration. No iOS target or bundle
ID was supplied. See [Flutter Android integration](https://pub.dev/packages/google_sign_in_android).

The client launches Google's Android account picker and sends only its short-lived
ID token to `POST /v1/auth/google`; then it retrieves `/v1/auth/me` with the
issued FIKRAH access token and stores the FIKRAH pair in the existing secure
vault. Cancellation leaves the FIKRAH session unchanged. The optional provider
name is sent as the existing backend fallback; a documented missing-name 422
prompts the user and retries the same assertion without storing it persistently.
No token, provider exception or server response body is shown or logged.

Tests cover successful exchange/account lookup, cancellation, name fallback,
invalid-token mapping, existing login and AR/EN registration. A deployed negative-token probe returned 401 as expected. On-device owner-selected Google sign-in succeeded: the server returned HTTP 200 for the exchange and the account lookup, and the owner confirmed reaching Home. Other account-linking, cancellation on a real device and release signing configurations remain separate checks.
