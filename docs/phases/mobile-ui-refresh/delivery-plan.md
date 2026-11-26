# Mobile UI refresh delivery plan

Status: supported mobile journeys and lighter typography implemented; backend work is owned by the user.
The feature [backend handoff](../../features/mobile-ui-refresh/backend-handoff.md)
lists missing capabilities and unresolved product rules. Six-digit codes and
flexible backend-suggested categories are confirmed; numeric code limits and
habit/achievement formulas are not approved.

## Executed checks

117 focused tests passed, including product controllers/capture/authentication,
reference journeys at 360dp in Arabic/English and light/dark with 1x/2x text,
real Inter/Noto shaping and metrics, contrast, branded headers, welcome,
localization, implicit General/create/select/delete project behavior, legacy
main-screen large text and TalkBack/semantics. Flutter
analysis reports no issues. Journey captures were generated with the real
bundled fonts and inspected in both languages. The product palette is separate
from the legacy demo palette; shared typography is lighter in both journeys.

Local validation logs: `build/validation/ui-typography-tests.log` and
`build/validation/ui-typography-analyze.log`; the final project-control
regression is `build/validation/ui-general-tests.log`. Screenshots are generated under
`build/validation/mobile-ui/` and stay outside source control.

1. Agree the new feature inventory, persistence/API ownership and behavioral
   differences from the HTML prototype. Record decisions in the feature scope.
2. Refresh shared mobile presentation and the supported welcome/auth, home,
   capture, note, graph, chat and profile/settings journeys.
3. Implement newly approved capabilities in independent feature branches, with
   explicit contracts/development fixtures where real endpoints are unavailable.
   The exact feature order depends on the requirements discussion.
4. Run controller and widget regressions, real-font large-text/RTL/accessibility
   checks, visual comparisons, and a resource-limited physical-device build when
   the phone is available. Report live-backend limitations accurately.
5. Push only complete branches and create/merge PRs targeting dev using merge
   commits. Never include unrelated user documentation moves or local AGENTS.

## Physical-device delivery order

The user requested that ready changes appear on the attached phone as work
progresses. Install and open each small verified update on the physical device
before waiting for pull-request publication or merge. Keep resource limits for
local builds (two CPU cores, one Gradle worker, 1 GiB Java heap); do not start
an Android emulator or an additional IDE session.

## Device build and installation

The ARM64-targeted profile build completed successfully with the resource limits
above. The APK retains application label `FIKRAH` and package
`com.fikra.app.stress`. Installed using `adb install -r` on the attached Xiaomi
M2010J19SG (`e1f598040421`), then launched the existing MainActivity successfully.
App data was retained. Installation preceded PR publication, as requested.

The phone was asleep/locked during the initial visual check; the user was asked
to unlock it. Widget screenshots verify the updated typography and implicit
General layout in the meantime. Build log: `build/validation/ui-build.log`.
