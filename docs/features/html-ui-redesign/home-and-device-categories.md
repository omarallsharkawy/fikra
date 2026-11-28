# Home and device categories

Home now follows the source greeting, search field, category pills, Today/Earlier groups, 18dp note cards, 13.5dp previews and processing dots. It renders repository notes and search results, not the HTML's samples. The first content line replaces absent or placeholder titles exactly as the reference does. The existing selected project remains the API scope; project selection and management stay in Settings, without bringing the large selector back to Home.

Typing triggers the existing repository search after 350ms; submitting searches immediately. A project change cancels stale scheduled input, and the controller discards stale responses. Search scores are not displayed as fabricated relationship confidence. Pull to refresh retains a recovery path for loading failures. The native empty screen uses the reference's first-idea action. User-created category filters also apply to retrieved search results through the local note-ID assignments.

Categories are explicitly separate from backend concepts. Until a category API exists, a single serialized device store retains a per-account catalog (`id`, `label`, semantic `color` index) and `note_tags` assignments. No category names are seeded in the production client. Color indices use purple, blue, orange and muted semantic colors; they adapt to the theme. Unicode labels are trimmed and empty labels rejected; existing labels are reused without duplicating them. Editing/assigning UI is shared with note detail and capture. The missing server capability is recorded in `BACKEND_REQUESTS.md`.

Older accounts receive a neutral greeting and a one-time inline name prompt. Adding a name opens a root-level sheet so the floating navigation cannot cover its Save action. The account boundary replaces the entire navigator on sign-out, preventing private sheets from leaking to another account. Dismissing the prompt records the choice on this device. A stored name is used with bidi isolation in the greeting; name fields detect their script. Platform emoji remain platform-rendered; visual tests load the host emoji font when available.

## Visual comparison

`tool/prepare_ui_reference.mjs` creates a screenshot-only host with a 398×650 content frame and hidden desktop scrollbars. It removes the prototype's desktop rounded phone border, without modifying component CSS or the canonical `design/fikrah-ui.html`. This avoids comparing Linux desktop scrollbar widths against the native mobile scroll view. Test-only repository records and categories are extracted into `test/support/fixtures/`; none are Flutter assets or production fallbacks.

The approved floating glass navigation intentionally replaces the original HTML bar. Interactive pills retain 44dp targets while using the reference's 32dp visible shape; the invisible target occupies the existing padding beneath the filter row. Browser and Flutter text rasterization can differ slightly, while the semantic colors and geometry come from the same source.

Validation covers repository-backed searching, Unicode name editing, local filtering, per-account isolation, one-time prompts, error recovery/empty states, and all four language/theme screenshot combinations. Reduced-motion captures are separate from motion interaction tests.
