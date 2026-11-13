# Test support

`app_harness.dart` boots the real router/app on an in-memory Drift database and disposes it inside each test. `fikraTest` accepts locale, brightness, clock, file-opener and PDF-loader overrides. The default PDF loader throws a missing-file error without disk I/O or native PDFium initialization; a supplied loader can model other outcomes. Attachment maintenance is a no-op fake.

`pumpUntil` and `pumpFuture` bridge database work and fake time. `loadAppFonts` and `saveScreenshot` support deterministic screenshot fixtures under `build/screenshots`, with a boundary around the whole app.

Verification: `flutter test` and the screenshot-tagged suite.

The harness accepts optional repository, recorder factory, microphone permission, AttachmentStore and AiService overrides for transactional file flows and analysis-call assertions. `mockAudioPlayers` supplies local method/event channels for preview rendering, without native audio. The fake records loaded paths and native init/pause/play/dispose calls, and can hold a pause so widget tests prove recorder start waits for playback; device playback remains required.

`proposal_fixture.dart` renders the actual note-details screen with a pending proposal and stream-provider fixtures. It isolates large-text button layout from the covered tab shell and supports locale, theme, width and text scale while retaining real app typography. Its keyed scope can replace the app harness without changing an existing container’s override count.

`recording_fake.dart` implements the record platform boundary with real small file writes, state streams, native start/cancel gates, failure injection, active-recorder tracking and an event log. Tests retain AudioRecorder serialization, amplitude and editor stop transitions.

`fikraTest` also accepts a `LinksRepository` override (spies and failure injection for the links section and picker).
