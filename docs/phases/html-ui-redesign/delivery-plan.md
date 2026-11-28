# HTML redesign delivery

Source: `design/fikrah-ui.html`, copied without alteration from the owner-supplied `FIKRAH · UI Redesign (2).html`. The prototype was opened in a browser before implementation; Arabic/English, Light/Dark/System, authentication, filters/search, details/diff, map selection, chat, capture/voice, profile, action/confirmation sheets, and delete/undo were exercised.

Implement in this order: semantic tokens/shared components/localization; existing GoRouter shell navigation; authentication; Home; note detail; force-directed Map; Ask; Capture; Me. Keep Riverpod, GoRouter, JSON/Bearer, OTP, generation checks, idempotency, polling, SSE, and native transcription. Backend source, schemas, configuration and deployment are outside this change.

For each screen, render the real Flutter widget tree in Arabic/English and light/dark using injected test-only repository data, capture the unmodified HTML in matching modes, inspect side-by-side comparisons, and correct layout before proceeding. Test data must stay under test tooling and never become production fallbacks. Preserve loading/empty/error states and 44dp hit areas; document intentional differences required by live contracts/accessibility. Install mobile builds promptly on the connected physical phone and distinguish device checks from widget captures.

Capture baseline images before changing the current UI. Keep screenshots under `build/validation/redesign/` and write the final comparison report under `docs/features/html-ui-redesign/`. Record exact CSS values in `reference-values.json` and all backend gaps in root `BACKEND_REQUESTS.md`. Verify only mobile repository files changed, excluding the owner's pre-existing documentation moves.

## Approved navigation override

On 27 November the owner approved preview variant **2/2, Floating add**: a translucent floating capsule with 32dp rounded corners, a 20dp backdrop blur, a softly animated active indicator and press response, and a raised purple add button. This supersedes the original HTML navigation only. Keep the original routes and body designs. Use a single clipped blur surface, respect reduced motion, retain labels at large text sizes, and reserve enough bottom content space to keep actions reachable. The brand purple adapts to each theme; the plus uses a contrasting foreground. Preview files live outside production code and contain no account data.

## Local build resource budget

Android defaults now use a 1 GiB Gradle heap, 384 MiB metaspace and 96 MiB code
cache, with one worker, parallel execution disabled, in-process Kotlin compilation,
and no persistent Gradle daemon. These replace the template's 8 GiB heap and
4 GiB metaspace allowances; allowances are not measurements of actual use.
Gradle sees at most two processors. Run APK builds and Flutter tests sequentially
and use `flutter test --concurrency=1`; avoid leaving preview/test processes
running between checks. These settings affect developer builds, not mobile
application memory limits or API behavior. Native builds may take longer than
with unconstrained parallel execution.
