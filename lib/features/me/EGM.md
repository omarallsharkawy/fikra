# Me

`MeScreen` is shell branch 4 at `/me`; `/settings` redirects here. It composes the
existing settings screen with project management and local activity statistics.
No account, handle, achievements or logout are shown.

`meStatsProvider` aggregates the selected project's shared notes and links
streams once. Confirmed links are unique undirected user pairs with existing
endpoints, excluding dismissed rows. Active days are local calendar days from
today through six days ago, excluding future notes. It refreshes at midnight.
`MeStatsTiles` uses RollingText and the concept's blue, purple and lime fills.

Verification: me_test.dart, concept_navigation_test.dart, screenshot matrix.
