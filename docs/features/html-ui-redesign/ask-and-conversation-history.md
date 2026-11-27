# Ask and conversation history

Ask follows the HTML's 68px header, history/new-chat icons, scope badge, 56px
empty-state icon, 19px heading, 44px prompt chips, 88%-width bubbles, 18px radii,
12×14px message padding and citation pills. The assistant edge uses the exact
3px logical-start purple border and 1px neutral borders. A custom rounded shape
paints this because Flutter's stock rounded border rejects different side colors.
User-bubble direction follows its content; the assistant border and controls
mirror with the interface. Dynamic project names use bidi isolation.

Opening Ask does not create a conversation. A prompt explicitly creates one when
needed, then sends through the existing repository. Questions, partial SSE text,
confirmed messages and references are real repository values. Partial text has
a localized replying status and no invented sources. Citation count and links
come from returned references; unsupported-answer status remains authoritative.
Missing feedback actions stay hidden. Prototype answers, fixed citation counts
and sample notes never become production fallbacks.

The HTML defines question-input CSS but never renders the input, and its history
button is inert. Mobile keeps the working composer, styled from `.inp`, after
creating/opening a conversation, with explicit Send. History lists, opens,
creates and deletes actual conversations through existing routes and confirmation
flow. These are intentional functional additions, not new backend contracts.
Scope names the selected project when others exist; it never claims account-wide
retrieval for a project-scoped request.

The empty view starts at the top. Incoming text follows only while the reader is
near the bottom; edits to the next draft during a reply are retained. The composer
reserves space above the floating bar and keyboard. Stop waiting/reconciliation
keeps uncertain-send protections: check history before another intentional send,
with no automatic replay. Confirmation sheets explicitly close the root modal
navigator rather than popping a shell page.

## Verification

- Four-mode empty/answered captures: `build/validation/redesign/{reference,after}/ask-*`.
- Comparison sheets: `ask-empty-comparison.png` and `ask-answered-comparison.png`
  in that validation directory. These render real Flutter widgets with test-only
  repository overrides, not owner data or physical-device screenshots.
- `test/product/redesign_conversation_test.dart` exercises prompt intent, partial
  versus confirmed output, actual citations, draft preservation during streaming,
  root confirmation cancellation, source navigation and history deletion in AR/EN.
- `test/product/chat_frames_test.dart` retains UTF-8/SSE integrity checks;
  malformed/incomplete data never becomes an authoritative completion.

The visible composer and working history have no interactive equivalent in the
prototype. Navigation follows the approved glass variant. Native text rasterization
differs slightly from browser text; other compared empty/answered geometry derives
from the supplied CSS and copy.
