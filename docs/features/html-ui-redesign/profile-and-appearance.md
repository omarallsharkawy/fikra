# Me, device profile and appearance

Me follows the reference's 68dp avatar with 3dp lime ring, 19px name,
13px email, 22px count cards, semantic surfaces and language/theme segments.
The existing Settings entry stays accessible through a 44dp header action
without moving the source body. Names are editable through the account-scoped
device profile form; existing accounts can add a name rather than receiving
a fabricated default. Real notes and graph links are scoped to the selected
project, with explicit scope shown when other projects exist. Failed count
requests show an unavailable value and retry, never a misleading zero.

AR/EN and Light/Dark/System update the existing settings streams live.
Unsupported auto-tag configuration stays hidden. Export opens the native
Android chooser with real freshly fetched project notes, timestamps, concepts
and device tag labels in JSON; it explicitly describes selected-project scope.
The chooser is hidden on platforms lacking the current native capability.
No account-wide completeness, server-side name update or uploaded PDFs are
implied. Sign out requires the localized confirmation sheet. The unused raw
logout and unconfigured-Google notices are removed from localization resources.

`redesign_me_test.dart` verifies editable names, live bilingual switching,
Light/System behavior, real-content export, sanitized share failures, cancel
and sign out at 1×/2× text sizes. Four-mode reference/widget captures live
under `build/validation/redesign/{reference,after}/me-*`. The hidden auto-tag
row and retained Settings action are intentional functional differences.
