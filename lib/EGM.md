# lib

## Overview

All application source for FIKRA, a local-first Arabic notes app for Android. `main.dart` starts the app. The four subpackages split the code by role: `app` wires it together, `core` holds shared presentation code, `data` owns storage and the AI boundary, and `features` holds the screens.

## Interface

- `main.dart`: `main()`.
- Subpackages:
  - [app](./app/EGM.md): `FikraApp`, `routerProvider`, the Riverpod providers, `AppShell`, `appMode`.
  - [core](./core/EGM.md): `Fmt`, theme tokens, motion tokens, shared widgets.
  - [data](./data/EGM.md): repository interfaces and their local implementations, `AiService`, `AttachmentStore`, `openWithSystem`, `NoteProcessor`, `FikraDatabase`.
  - [features](./features/EGM.md): one folder per screen group.

## Invariants

- [`main.dart:main`] throws `UnsupportedError` before `runApp` when `appMode == AppMode.connected`. Connected mode must not run on the demo services. This check must be removed when the backend is wired in.
- [`main.dart:main`] calls `initializeDateFormatting('ar')` before `runApp`. `Fmt` date formatting depends on it.

## Side Effects

- [`main.dart:main`] loads Arabic date symbols and starts the widget tree inside a `ProviderScope`.

## Verification

- Run: `flutter analyze && flutter test`
