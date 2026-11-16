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
HorizontalDragGestureRecognizer uses normal Flutter horizontal slop with
DragStartBehavior.down. A Listener starts the lens and selects on pointer-down
without waiting for the recognizer. Raw moves update the lens and check vertical
leave; accepted horizontal updates change tabs. Leaving more than 60 dp above or
below the 72 dp bar cancels for the rest of that pointer. Pointer cancel, release,
and keyboard opening settle to the current selection. Only the owning pointer
can end the gesture. A tap on the current tab requests initialLocation; traversing
back to it never resets its stack. A generation counter prevents interrupted
spring completion from fading a newly pressed lens.

The lens is 88 dp tall and one tab plus 20 dp wide; its centre is clamped to tab
centres at the ends (5 dp shape overhang outside the bar). An unbounded animation
controller drives a Transform, never shell setState. The hover ValueNotifier only
changes at tab boundaries. A separate 140 ms pulse controller fades the lens into
the opaque selected pill after a mass-1 / stiffness-420 / damping-24 spring.
Reduce Motion removes the spring and icon scale, retaining pointer tracking/fade.
Only changed tab indices navigate and call HapticFeedback.selectionClick.
The background and label row have RepaintBoundaries; child branch navigators
never listen to either controller. The existing branch veil is unchanged.

`tab_label.dart` supplies button/selected/label/tap Semantics, keyboard activation,
and the accent icon (1.13 scale while held). Visible labels stay one line with
ellipsis and cap text scaling at 1.4 to preserve the minimum 48 dp touch targets.
TalkBack uses its own tap callback and never needs to slide.

GlassLens chooses optics or the same capsule with frosted/solid material. Its
native shader opacity preserves refraction during release; no Opacity encloses
the optical lens. The overlapping fallback has its own backdrop key, separate
from the non-overlapping bar/Add shared key. The bar/Add key is one static
`BackdropKey`, so it stays stable across rebuilds and does not repaint both glass
layers on every tab switch. The lens settles with a pixel-level spring tolerance
(about 0.4 s) and follows only the first finger; a tab change made elsewhere ends
the press or retargets the settle.

Verification: floating_navigation_test.dart, floating_shell_test.dart, the
floating_navigation screenshot matrix and glass_widget_test.dart. The profile
slide workload is in integration_test/glass_perf_scenario.dart. Do not run the
phone workload in the restricted environment.
