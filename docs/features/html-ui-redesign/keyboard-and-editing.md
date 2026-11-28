# Keyboard-safe writing and note editing

The shell restored an ancestor MediaQuery with the full IME inset after its own
Scaffold had already reduced the body. Capture and Ask then resized their own
Scaffolds again, potentially leaving no usable editor. The product shell now
leaves resizing to its active page. Navigation still hides for the keyboard;
legacy/demo shell behavior is unchanged.

Capture retains the focused editor, cursor, text and scroll state while its
keyboard dock changes. Voice/PDF/Tag stay available as labeled icon actions
next to Save; on short viewports Cancel moves into that dock too. The regular
HTML toolbar/header remains when the keyboard is closed. Keyed editor
subtrees prevent focus and caret position from being lost when chrome moves.

Ask limits the composer's line count to the available height, keeps Send
reachable and scrolls within longer input instead of consuming the page.
Shared page headings stay on one line to avoid oversized headers pushing
writing controls below the keyboard at larger accessibility text sizes.

The note-edit sheet uses the redesign fields and a bounded scrollable editor,
with explicit Save fixed below it. Long notes can be reviewed and edited
without scrolling the save action off-screen. No mutation or API contracts
change; opening/closing the keyboard never saves or sends content.

Verification: `keyboard_layout_test.dart` exercises 36 scenarios across Capture,
Ask and note editing: AR/EN UI × AR/EN content, 360×640 with a 340dp IME at 1×/2× text, and
640×360 with a 180dp IME. It checks caret bounds, editor clipping, focus,
keyboard reopening, retained text, hit-testable actions and actual Save/Send.
The shared component and complete host regression suite pass (1,065 tests,
16 conditionally skipped on 2026-11-28). Capture reserves an additional 44dp
above its keyboard action row so native selection handles cannot cover Save.
Screenshots are synthetic widget renders under `build/validation/redesign/keyboard/`;
they do not claim to be physical Android keyboard screenshots.
