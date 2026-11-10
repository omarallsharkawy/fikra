# Test support

`app_harness.dart` boots the real router/app on an in-memory Drift database and disposes it inside each test. `fikraTest` accepts locale, brightness, clock, file-opener and PDF-loader overrides. The default PDF loader throws a missing-file error without disk I/O or native PDFium initialization; a supplied loader can model other outcomes. Attachment maintenance is a no-op fake.

`pumpUntil` and `pumpFuture` bridge database work and fake time. `loadAppFonts` and `saveScreenshot` support deterministic screenshot fixtures under `build/screenshots`, with a boundary around the whole app.

Verification: `flutter test` and the screenshot-tagged suite.
