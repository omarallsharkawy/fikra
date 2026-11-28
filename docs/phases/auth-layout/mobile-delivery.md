# Account layout delivery

## Phase 1 — Presentation and input review

Implement the approved account layout refinement on a feature branch from dev. Preserve authentication contracts and the existing typography choices. Validate all account stages with keyboard, RTL, themes and enlarged text.

## Phase 2 — Device delivery and integration

Build a profile ARM64 APK with two CPU cores, one Gradle worker and a 1 GiB Gradle heap. Install on the connected physical Android phone as soon as the focused checks pass. Run the broader relevant regression suite and static analysis before merging a pull request into dev with a merge commit.

## Verified results

- 135 relevant tests pass: product/controllers/journeys plus brand, typography, contrast, localization, large-text and accessibility regressions. The eight new account journeys run at 360 x 800 dp across both locales, both themes and 1x/2x text, including a 300 dp keyboard.
- Flutter static analysis reports no issues. Diff whitespace checks pass.
- Real-font Flutter screenshots of welcome, sign-in, registration, verification, recovery request/acknowledgment and reset were inspected in English/Arabic and light/dark.
- The initial layout APK and final form-navigation fix both built successfully and were installed with `adb install -r` on the connected Xiaomi M2010J19SG. Android reported successful activity launches. Existing app data was not cleared. The final build used two CPU cores, one Gradle worker and a 1 GiB heap and completed in 100 seconds.
- The phone screen had returned to sleep during builds, so physical-screen visual review was unavailable; rendered-screen inspection and device install/launch are separate evidence.
- The canceled animation pass was not installed or included. The final APK contains only this account-layout feature on top of the merged UX work.
- Local AGENTS.md remains ignored. Unrelated backend documentation moves remain outside this change.
