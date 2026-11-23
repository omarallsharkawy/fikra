# Settings controls in Me

`SettingsScreen` is the retained settings composition inside `MeScreen`, shell
branch `/me`. `/settings` redirects there; `/settings/voice-text` and service deep
links remain pushed routes with existing transitions.

The scrollable screen presents Me, three aggregate stat tiles, Projects (the
existing switch/create/rename/delete sheet), Appearance & language, Voice &
services, Privacy & data, and About. Erase all sits alone in red below a divider.
Reading content uses SolidSurface; bottom padding follows NavigationInset.

Theme and language SegmentedPill orders remain system/light/dark and system/ar/en.
Services and data-location copy follow transcriptionServicesStateProvider; remote
copy names the selected service, and loading/error never claims local-only data.

Wipe still requires confirmDestructive. It captures the messenger and localized
messages before awaiting wipeAllData; WipeFilesException retains its partial-file
message. The router returns to welcome when no projects remain. Appearance and
language persist through wipe; service configs and keys are removed.

Verification: me_test, phase4_ia_test, app_flow_test, localization_test, screenshots.
