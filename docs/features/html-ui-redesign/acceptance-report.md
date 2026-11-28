# Mobile redesign and RTL acceptance report

Reference: `design/fikrah-ui.html`, with the owner's approved 2/2 glass-navigation
variant and subsequent removal of the redundant Ask scope strip. The Flutter
client retains Riverpod, GoRouter and the existing JSON/Bearer API contracts.
No server, database, AI pipeline, authentication configuration or infrastructure
implementation belongs to this change.

## Visual evidence

Open [the comparison gallery](visual-evidence/index.html). It separates the
original mobile baseline, unmodified HTML reference and revised Flutter client.
Choose screen, language and theme; the RTL matrix adds independent content
language at 130% text. Missing baseline images for newly captured extra states
are labeled as missing rather than substituted.

The captures use synthetic test-only repository overrides, never production
fallback data. Native device screenshots stay private and are not included.
The prototype changes its sample content with its language; cross-language
content tests therefore have no independent equivalent in that prototype.

| Screen | Before | After and intentional differences |
| --- | --- | --- |
| Landing | Previous authentication entry layout | Reference hero/cards, typography, theme and bilingual copy; navigation uses real authentication routes |
| Sign up | Empty Arabic inputs could align left; existing registration omitted the newly required server name | Required trimmed name first, valid name/email/password gating, UI-aligned empty fields, content-aware filled fields; real six-digit OTP instead of mock password tricks |
| Login / recovery | Direction handling duplicated by form | Shared empty/identifier rules, localized real errors and six-digit existing recovery flow; unconfigured Google entry stays hidden |
| Home | Previous cards/search/projects layout | Reference spacing, real notes/search, separate device tags, account name greeting, contextual empty/error/loading states; project management lives in Settings |
| Note detail | Previous editing/refinement presentation | Real word diff, generation-aware refinement, related notes, tags, favorite, native share and durable deferred Undo; unsupported scores/reasons are hidden |
| Map | Previous graph presentation | Real graph data with deterministic force layout, pan/zoom/drag/selection, per-label direction and real note opening; no prototype positions or invented links |
| Ask | Previous conversation layout and redundant All notes strip | Real SSE, citations, history, stable sender-side bubbles, keyboard-safe composer; default strip removed, genuine project scope preserved |
| Capture | Previous writing/recording arrangement | Draft autosave, explicit Save, stable cursor/viewport with IME, single-consumption native transcript; local PDFs remain local and no sample transcript is shipped |
| Me | Previous profile/preferences layout | Real profile name/read, editable device fallback where no update API exists, live AR/EN and Light/Dark/System, actual selected-project counts and export |

Native text rasterization and Arabic line boxes differ from browser rendering.
The RTL audit also retains an open narrow-line mixed-input issue: parenthesized
Latin units can split/reorder under native bidi editing. It is recorded explicitly
in [the RTL defect table](../../rtl-audit.md), not counted as fixed or production
accepted. Raw input/IME values are not mutated with invisible display controls.
Inter/IBM Plex Sans Arabic and 1.6 Arabic line height follow the owner's explicit
font/accessibility requirements. Touch targets are at least 44dp. Backend-dependent
prototype controls are implemented only when supported or have the documented
truthful fallback in [BACKEND_REQUESTS.md](../../../BACKEND_REQUESTS.md).

## Verification completed

- Complete host suite: 1,065 passed, 16 explicitly skipped on 28 November 2026.
  Fifteen legacy screenshot suites are opt-in; one public live HTTPS smoke test is opt-in. The redesign capture suite runs normally.
- After the final dialog contrast correction, 36 targeted tests passed, including
  shared RTL/LTR goldens, OTP digit/IME handling, failed-processing recovery and
  real controller/AR/EN Ask intent/history tests.
- Updated screenshot execution: 48 normal captures and 104 RTL/content captures passed; all eight comparison sheets were visually inspected.
- Opted-in live HTTPS smoke: 1 passed (health/readiness/schema/protected-route rejection).
- Keyboard regression: 36 combinations of editor (Capture/Ask/edit), UI language,
  content language, small/landscape viewport and accessibility text scale.
- User confirmed actual account creation/email verification and arrival at Home.
- APK update retaining app data and its installed SHA-256 were verified on Android.
  This is installation verification, not completion of device E2E.

## Device acceptance still required

`integration_test/mobile_journeys_test.dart` drives the real connected client with
no provider/repository overrides. It creates only a uniquely named QA project,
checks four UI/content combinations, Android IME/caret/actions, draft reopening,
save/edit/pin, actual search/graph, available proposal Undo, delete Undo and real
SSE/history, then removes its own project and restores preferences.

The initial execution exposed a profile-test text-injection limitation; the
harness now uses the public EditableText IME client method instead of the
debug-only text-input client ID. The corrected run was blocked by Android's
`INSTALL_FAILED_USER_RESTRICTED` response. It is **not counted as passing**.
No existing user note was edited or deleted. Native voice recording, PDF picker,
share chooser, offline/session recovery and final user acceptance remain separate
checks. No production-ready claim is made while these gates remain open.

Google sign-in still needs the Web application client ID accepted by the backend;
the provided Android client ID cannot replace it. The test package is
`com.fikra.app.stress`. Store/release signing currently uses the repository's debug
signing configuration and requires the owner's release identity before a store
handoff. No iOS target or Bundle ID is invented.

## Reproduce

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter test --no-pub --concurrency=1 \
  test/screenshots/html_redesign_test.dart
flutter test --no-pub --concurrency=1 \
  --dart-define=RTL_AUDIT=true --dart-define=REDESIGN_CAPTURE=rtl-after \
  test/screenshots/html_redesign_test.dart
FIKRA_LIVE_SMOKE=1 flutter test --no-pub --concurrency=1 \
  test/product/api_live_smoke_test.dart
flutter drive --profile --no-pub -d <authorized-android-device> \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/mobile_journeys_test.dart
python3 tool/generate_redesign_gallery.py
```

Keep builds/tests sequential and use the repository's reduced Gradle resource
budget. Before rerunning device acceptance, authenticate in the normal profile
app and authorize USB installation. Restore a normal `lib/main.dart` APK after
the integration target; never uninstall/clear the app to get a passing test.

Changed implementation areas: `lib/core/{theme,widgets,text_direction.dart}`,
`lib/app/{shell.dart,tab_bar}`, authentication/profile, workspace/note/share/graph,
conversation, Capture, preserved local forms, localization, corresponding tests,
and the feature/phase/RTL/backend-gap documentation. The generated Unicode table
and golden/synthetic evidence have reproducible generators. The owner's unrelated
backend-documentation moves are excluded from commits.
