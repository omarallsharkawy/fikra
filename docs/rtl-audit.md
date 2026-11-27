# FIKRAH mobile Arabic and RTL audit

Scope: Flutter mobile, including the active connected client, settings, private local PDFs and preserved local/legacy screens. The backend, API schemas, navigation and state-management libraries are unchanged by this audit. The registration-name repair preceding this audit binds the already deployed schema.

Reference: `design/fikrah-ui.html`. The approved floating purple Add/glass navigation override remains in place. UI direction and content direction are independent. Digits remain Western 0–9, with no new preference, as explicitly requested on 2026-11-27.

## Inventory and defects

| Screen / component | Element | What's wrong | Rule | Fix | Status |
| --- | --- | --- | --- | --- | --- |
| Sign up | Empty name/email/password | Empty auto fell back to LTR; email/password forced LTR and physical alignment | 1–4 | Shared SmartInput uses UI direction while empty; identifiers become LTR at the UI start after entry; clearing restores UI direction | Host tests and visual matrix verified; device acceptance pending |
| Login, verification, recovery | Email/password/code | Same empty-field defect; technical direction leaked into placeholder alignment | 1–4, 10 | Input kind and keyboard semantics handled by SmartInput; decorators remain in UI direction | Host tests and visual matrix verified; device acceptance pending |
| Capture, note editor | Title and body | Physical left/right alignment and duplicated per-screen detection | 1–4, 7, 10 | Shared first-strong policy, logical alignment, unchanged selection/composition | Host tests and visual matrix verified; device acceptance pending |
| Capture / editable mixed text | Parenthesized Latin units at a narrow line boundary | Native bidi editing can split `(12 kg)` across lines and visually relocate its punctuation in the 130% mixed-content capture | 6, 10 | Keep raw values/selection/IME intact; a display-to-edit offset mapping would be required before introducing virtual isolates into editable spans | Open; not claimed fixed by the shared first-strong policy |
| Home, Map, Ask history | Search | Separate manual direction implementations; clear and paste not centrally covered | 1–4, 10 | SmartInput controller listener handles typing/paste/programmatic clear consistently | Host tests and visual matrix verified; device acceptance pending |
| Projects, tags, profile | Name forms | Native fields inherited UI direction regardless of entered content | 1–4, 10 | Same shared editable component, including preserved forms | Host tests and visual matrix verified; device acceptance pending |
| Legacy service configuration | URL/key/model ID | Outer LTR Directionality also moved placeholders and chrome | 1–4 | Keep UI ancestor; express identifier semantics only at the input | Implemented; host regression verified |
| All read-only text | Notes, titles, tags, filenames, transcript, chat | Several paths inherited UI direction or selected RTL whenever any Arabic appeared | 1, 6, 7, 11 | Shared SmartText and Unicode first-strong classification; isolate opposite-direction fragments only for display | Host tests and visual matrix verified; device acceptance pending |
| Shared detection | Leading emoji, punctuation, digits | intl's practical character ranges classified surrogate emoji as strong Latin | 1, 6 | Unicode 16 L/R/AL range lookup over code points; skip isolated fragments, combining marks, emoji and digits | Host tests and visual matrix verified; device acceptance pending |
| Ask | User bubble placement | Sender bubble moved according to the text's language | 1, 11 | Logical end for user, logical start for assistant; text direction remains independent | Host tests and visual matrix verified; device acceptance pending |
| Buttons, chips, tabs, headings, sheets, snackbars | Font and line box | Legacy Arabic used Noto, several line heights below 1.5 | 7–8 | Inter with IBM Plex Sans Arabic fallback, zero tracking, 1.6 line height through shared text/input and theme | Host tests and visual matrix verified; device acceptance pending |
| Graph | Labels and semantics | Legacy canvas label direction followed UI rather than each label | 1, 6, 7, 11 | Same content-direction policy in canvas and semantics; physical graph coordinates remain data geometry | Implemented; host regression verified |
| Note | Styled proposal diff | Rich text bypasses shared read-only policy | 1, 6–8 | Shared rich text rendering with original styles and per-paragraph direction | Implemented; host regression verified |
| Navigation, selectors | Selection position | Manual physical offsets duplicate RTL calculations | 4–5, 12–13 | Logical selected position and directional widgets; retain pointer/canvas coordinates where physically defined | Host tests and visual matrix verified; device acceptance pending |
| Shared icons | Back/disclosure/regenerate | Custom painter relies on each caller remembering to flip | 5 | Shared icon names mirror automatically; logos/checkmarks/media/clock/numerals stay unchanged | Host tests and visual matrix verified; device acceptance pending |
| Share card | Title, body, tag fragments | Canvas text needs same direction/isolation/font policy | 6–8, 13 | Shared display helpers in TextPainter, logical logo edge; no sample content | Implemented; host regression verified |
| Counts and dates | Citation summary and standalone counts | Plain interpolated citation count lacks Arabic plural forms | 6, 9 | ICU Arabic forms; locale format standalone counts and keep 0–9 | Implemented; host regression verified |
| Platform surfaces | PDF canvas, system share chooser, status bar, notifications, splash, app name | Must distinguish UI-owned chrome from document/system geometry | 5, 8, 13 | Audit native resources and device behavior; do not mirror document pages or the logo | Pending final device verification |

## Test matrix and evidence

Before captures: `build/validation/redesign/rtl-before/`: 104 synthetic Flutter screenshots at 398×650, 130% text, AR/EN UI × AR/EN content × light/dark, covering Landing, sign-up empty/filled, Login, Home, Note, Map, Ask empty/answered, Capture empty/filled/recording and Me. No real account data is included. These are widget-rendered screenshots, not claims about physical keyboard behavior.

Additional cases: empty/cleared fields, diacritics, one character, long two-line clamps, leading punctuation/emoji/numbers, `ال Deep Learning يعني إيه؟`, `محمد @ Microsoft`, URLs, paste, selection/composition ranges, keyboard resize, theme/language switching, and component goldens. Status and remaining device-only checks are updated after execution rather than inferred from compilation.

The prototype cannot independently switch its sample read-only content language; its language toggle changes the samples too. Cross-language real-content cases are therefore tested in the Flutter client. Only supported prototype interactions are used for reference captures.

## Geometry exceptions

Physical x/y in graph force layout, canvas paths, pointer-hit coordinates, PDF page coordinates, and decorative gradient/light geometry are data/paint coordinates, not UI start/end. Equal SDK-only EdgeInsets are expressed with symmetric padding. Logos, media controls, clock icons and numerals intentionally do not mirror. No blanket mirroring of user documents is applied.

## Execution record — 28 November 2026

- Complete host suite: **1,065 passed**, 16 skipped by explicit configuration
  (15 legacy screenshot suites require `--run-skipped -t screenshots`; one public live
  HTTPS smoke test requires `FIKRA_LIVE_SMOKE=1`). No test was skipped to hide a
  failure. Log: `build/validation/redesign/full-suite-rtl-final.log`.
- Additional shared-input/contrast, failed-processing recovery and AR/EN Ask
  checks after the Material dialog contrast repair: **36 passed**. This also
  checks committed Arabic/Persian OTP digits and preservation of IME composition.
- Public live HTTPS smoke: **1 passed** (health/readiness, OTP schema and protected-route rejection), explicitly opted in after the host suite.
- Final redesign captures: **48 passed** at normal scale and **104 passed** in the independent UI/content 130% matrix. All eight updated comparison sheets were inspected.
- Shared component goldens cover AR/EN direction, empty/Arabic/English/mixed
  values, both themes and 130% text. Keyboard geometry regression covers 36
  UI-language/content-language/viewport/editor combinations.
- The Ask default All notes strip was removed at the owner's request; custom
  project scope remains accurate. AR/EN conversation and selected-scope
  regression tests pass.
- Profile APK installation on Android was verified by SHA-256, without uninstall
  or data clearing. Physical keyboard/backend journeys are a separate acceptance
  gate; a failed automation attempt is not counted as a passing journey.

Editable values are never decorated with invisible isolation controls: Android's
native Unicode bidi editing, selection and IME behavior retain the original raw
text. Read-only presentation uses FSI/PDI around opposite-direction fragments.
Native system share/keyboard/notification typography belongs to Android; the
client does not replace system UI or fabricate unavailable push/widget surfaces.
