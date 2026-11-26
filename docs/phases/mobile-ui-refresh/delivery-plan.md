# Mobile UI refresh delivery plan

Status: visual foundations implemented; backend work is owned by the user.
The feature [backend handoff](../../features/mobile-ui-refresh/backend-handoff.md)
lists missing capabilities and unresolved product rules. Six-digit codes and
flexible backend-suggested categories are confirmed; numeric code limits and
habit/achievement formulas are not approved.

## Executed foundation checks

17 focused tests passed: reference palette contrast, central capture navigation
in Arabic/English at 2x text, hidden-navigation interactions, password visibility,
existing product navigation and real-font branded headers. Theme changes apply
to the product journey; the separate legacy demo retains its previous theme.

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
