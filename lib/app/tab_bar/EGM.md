# Floating shell navigation

`floating_navigation.dart` owns the 72 dp floating row, 56 dp gradient Add button,
100 ms keyboard fade/slide, selected Add ring and shared BackdropGroup. Its three
visible tabs map to persistent shell branches 1, 2, 3; Add remains branch 0.
The maximum bar width is 280 dp, with 5 dp inner padding; the row shrinks on phones.
The bar always fills the width the row offers: its Stack's only unpositioned child
is the hidden lens, so without an explicit width it would collapse to 0 dp and
paint its tabs where no tap can reach them.
The shell positions it 12 dp above the bottom safe area. Labels reuse navNotes,
navLinks, navAsk and navAdd. RTL places Notes rightmost and Add left of the bar.

`sliding_tab_bar.dart` owns the gesture and capsule. A scoped
`_OwnedHorizontalDragRecognizer` (`HorizontalDragGestureRecognizer` subclass that
ignores pointers while `!enabled` or another pointer owns the bar) uses normal
Flutter horizontal slop with `DragStartBehavior.down` and
`onlyAcceptDragOnThreshold = true`. A Listener selects on pointer-down and starts
a `kLensHoldDelay` (200 ms) timer without showing the lens; plain taps keep lens
opacity at 0 throughout and after. The lens engages either when the 200 ms hold
timer fires or as soon as horizontal drag is accepted. Raw moves check vertical
leave and update the lens once engaged; accepted horizontal updates change tabs.
Leaving more than 60 dp above or below the bar cancels for the rest of that
pointer. Pointer cancel, release, external index changes, keyboard disable
(`!enabled`), and dispose cancel any pending hold timer (guarded by a generation
counter) and settle when the lens is visible; `_finish()` rejects the active
pointer on the drag recognizer so a new press while an old cancelled finger is
still down must cross its own horizontal slop or wait 200 ms. Only the owning
pointer can end the gesture. A tap on the current tab requests initialLocation;
traversing back to it never resets its stack.

The lens is 88 dp tall and one tab plus 20 dp wide; its centre is clamped to tab
centres at the ends (5 dp shape overhang outside the bar). An unbounded animation
controller drives a Transform, never shell setState. The hover ValueNotifier is
set only while the lens is engaged and changes at tab boundaries. On release
after an engaged lens, the 140 ms pulse controller starts fading the lens into
the opaque selected pill right away, alongside the mass-1 / stiffness-420 /
damping-24 spring settle, and stops the position controller as soon as the fade
is dismissed (~140 ms). Plain taps start neither controller.
Reduce Motion removes the spring and icon scale, retaining pointer tracking/fade.
Only changed tab indices navigate and call HapticFeedback.selectionClick.
The background and label row have RepaintBoundaries; child branch navigators
never listen to either controller. The existing branch veil is unchanged.

`tab_label.dart` supplies button/selected/label/tap Semantics, keyboard activation,
and the accent icon (1.13 scale while the lens is held over that tab). Visible labels stay one line with
ellipsis and cap text scaling at 1.4 to preserve the minimum 48 dp touch targets.
TalkBack uses its own tap callback and never needs to slide.

GlassLens chooses optics or the same capsule with frosted/solid material. Its
native shader opacity preserves refraction during release; no Opacity encloses
the optical lens. The overlapping fallback has its own backdrop key, separate
from the tab bar and ActivityCapsule shared key. The Add button (`nav-add`) is
an opaque gradient circle with rim border and `glassShadows` and no `Glass` /
`BackdropFilter`. The bar/capsule key is one static `BackdropKey`, so it stays
stable across rebuilds and does not repaint both glass layers on every tab switch.
The lens settles alongside the 140 ms release fade and follows only the first
finger; a tab change made elsewhere ends the press or retargets the settle.

Verification: floating_navigation_test.dart, floating_shell_test.dart, the
floating_navigation screenshot matrix and glass_widget_test.dart. The profile
slide workload is in integration_test/glass_perf_scenario.dart. Do not run the
phone workload in the restricted environment.

## Motion & delight (redesign phase 7)

- `activity_capsule.dart`: `ActivityCapsule` (`ValueKey('activity-capsule')`). Floats 10 dp above the tab bar (start-aligned within the 280 dp bar column so it never overlaps `nav-add`), enters/exits via `FikraSwitcher`, shares `FloatingNavigation`'s static `BackdropGroup` and keyboard hide/fade/slide, and exposes static semantic button labels (`capsuleRecordingA11y` / `capsuleTranscribingA11y`). Uses a static red dot + 1 Hz `ValueListenableBuilder` around only the time `Text` (inside `RepaintBoundary`, leaving `Pressable`/`Glass` untouched) when recording on Add while viewing another tab, and a static icon + `capsuleTranscribing` while a background transcription job is running.
- `floating_navigation.dart`, `sliding_tab_bar.dart`, `tab_label.dart`: accept optional `ValueListenable<double>? shrink` (`0..1`). Keeps one stable `FikraNavBar` and `TabLabel` widget tree at rest and while shrunk, prebuilds `Glass` as a cached child and quantizes bar height to whole dp (`72 → 52 dp`) to avoid per-frame `Glass` relayout while keeping icons, hit targets, semantics and the press-and-slide lens intact.
