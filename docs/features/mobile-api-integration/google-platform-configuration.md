# Google platform configuration

The owner supplied the following **Android** OAuth client on 27 November 2026:

`109535867594-0gok833v4j10mtedhee5146g8r8dcgtn.apps.googleusercontent.com`

The APK installed for current physical-device testing has application ID
`com.fikra.app.stress` and certificate SHA-1
`5E:13:1A:11:45:AD:42:3A:E4:E8:E1:C8:A8:6C:0B:A1:9B:69:FF:56`.
These were extracted from the APK, which is a profile build signed with the
Android debug certificate. The base application ID is `com.fikra.app`; its
eventual release signing certificate is a separate configuration. The mobile
repository currently has no iOS target or verified bundle ID.

The Android client ID must not be substituted for the **Web application** client
ID used as `serverClientId` for Google ID-token acquisition. The owner has been
asked for that Web client ID from the same Google Cloud project and confirmation
that its audience is accepted by the backend. No client secret belongs in the
mobile app. See the [Flutter Android integration instructions](https://pub.dev/packages/google_sign_in_android).

Native acquisition remains pending until that identifier is supplied. The
existing exchange remains POST `/v1/auth/google` with JSON `{"id_token":"…"}`,
followed by authoritative account lookup and the current session/vault flow.
No server configuration or public API contract is changed by this document.
