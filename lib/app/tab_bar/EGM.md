# Floating navigation

`floating_navigation.dart` maps Home/Map/Ask/Me to branches 1–4; Add stays branch
0. The 72 dp glass pill has a 400 dp maximum width and 4 dp inner inset. A 56 dp
opaque gradient Add button sits outside it at the logical trailing end, across
an 8 dp gap. AppShell supplies 12 dp outer gutters and hides controls for keyboard
or Add, disabling input/semantics immediately before the 100 ms fade.

`sliding_tab_bar.dart` owns pointer tracking and controllers. `nav_bar_visual.dart`
is its paint/layout part; `owned_horizontal_drag.dart` gates drag ownership.
A plain press selects once, with one selection haptic per change; re-taps request
initialLocation without another haptic. The lens appears only after a 200 ms hold
or accepted horizontal drag. Cancel, vertical escape, external selection, disable
and disposal cancel the timer and reject the old drag pointer. Only its owner
can release. Lens tracking/release and Reduce Motion behavior remain local.

`nav_selection.dart` translates the translucent selection pill using the existing
FikraSprings.smooth (ζ=.75). Rapid taps preserve position/velocity and retarget;
no queued animations or layout per spring frame. Reduce Motion snaps.
`tab_label.dart` cross-fades icon/label colors with the same position, uses filled
selected icons, 12 sp labels with scale capped at 1.15 and 2 dp horizontal padding.
At system scale >=1.4 and tab width <72 dp labels hide, retaining button/selected/
label Semantics and keyboard activation. Keys nav-0..3 and nav-add are stable.

The optional shrink experiment retains stable Glass/label trees and quantized
height. ActivityCapsule shares the stable backdrop key and keyboard/Add hide path.
Live recordings and transcription use existing app-owned activity providers.

Verification: floating_navigation_test, concept_navigation_test, floating_shell_test,
branch_build_test, motion_test, and screenshots/floating_navigation_test.
