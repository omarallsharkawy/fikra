# Test support

`app_harness.dart` boots the real router/app on an in-memory Drift database and disposes it inside each test. `fikraTest` accepts locale, brightness, clock, file-opener and PDF-loader overrides. The default PDF loader throws a missing-file error without disk I/O or native PDFium initialization; a supplied loader can model other outcomes. Attachment maintenance is a no-op fake.

`pumpUntil` and `pumpFuture` bridge database work and fake time. `loadAppFonts` and `saveScreenshot` support deterministic screenshot fixtures under `build/screenshots`, with a boundary around the whole app.

Verification: `flutter test` and the screenshot-tagged suite.

The harness accepts optional repository, recorder factory, microphone permission, AttachmentStore and AiService overrides for transactional file flows and analysis-call assertions. `mockAudioPlayers` supplies local method/event channels for preview rendering, without native audio. The fake records loaded paths and native init/pause/play/dispose calls, and can hold a pause so widget tests prove recorder start waits for playback; device playback remains required.

`proposal_fixture.dart` renders the actual note-details screen with a pending proposal and stream-provider fixtures. It isolates large-text button layout from the covered tab shell and supports locale, theme, width and text scale while retaining real app typography. Its keyed scope can replace the app harness without changing an existing container’s override count.

`recording_fake.dart` implements the record platform boundary with real small file writes, state streams, native start/cancel gates, failure injection, active-recorder tracking and an event log. Tests retain AudioRecorder serialization, amplitude and editor stop transitions.

`fikraTest` also accepts a `LinksRepository` override (spies and failure injection for the links section and picker), and a `ProjectsRepository` override (`projectsRepository`) used to spy on and gate `deleteImpact`.

`fikraTest` also accepts a `GroupsRepository` override (`groupsRepository`). `selection_fixture.dart` (links phase 5a) holds the notes-list selection helpers: `phone` (tall screen, fatal hit-test warnings), `seedNotes` (Study + Work with per-note files), link/group readers, `card`/`reveal`/`select`/`tapAction` (scroll the lazy list and the sideways bar first), `waitOutToast`, a quiet `AiService`, and spies: `SpyLinks` (fail on a call), `SpyNotes` (moves, impacts, relinks, deletes, a failing delete, a held notes stream) and `SpyGroups`.

`host` (a bare themed app with the text scale applied above the navigator) also lives there. Review fixes: `SpyLinks` now counts `linkNotesForUndo` and has `linkGate` and `undoGate` completers; `SpyGroups.failAssign` makes assignments throw.

`fikraTest` accepts a VoiceTextBackend override for the Settings-only experiment's real-router screenshot fixtures. Existing tests and native audio mocks are unchanged.

Saved transcription: fikraTest accepts an optional TranscriptionEngine and always overrides the engine factory with a fake (including launch recovery). fake_transcription_engine.dart records paths/languages and accepts a gated/error action; FakeTranscriptionAi avoids leaving demo latency timers after unmount. fikraTest also always overrides the keep-alive (`FakeTranscriptionKeepAlive`, records `start N`/`stop`, optional `fail`) and the notification permission (`FakeNotificationPermission`, default not askable, counts `requests`), so no test reaches the foreground-service or permission channels; pass `keepAlive:` / `notificationPermission:` to inspect them. transcription_scroll.dart finds a page's unique outer Scrollable, excludes nested EditableText/Scrollable internals, and reveals plain keyed targets with an explicit scrollable. The helper uses no first/last/at finders.

`fikraTest` closes the database with `pumpFuture` in the test's zone. Work a test does not wait for, such as the note analysis a finished transcription starts, can still hold drift's lock; closing from `runAsync` waited for it forever and hung the file.

Phase 3 fake_external_transcription.dart supplies MemoryServiceKeys, FakeTranscriptionTransport and standalone MemoryTranscriptionServices with zone-owned, tear-down-safe watch streams. external_service_fixture.dart shares keyed engine/form/field/type actions through transcription_scroll; its dropdown taps do not use first/last/at. app_harness injects fake keys and HTTP for every test and a fake local engine even when selectedEngineFactory enables the real selection logic. No test can fall through to real HTTP/native Whisper. Pending queue/processor jobs must finish before the existing pumpFuture database close.

## Voice 2a

voice2_fixture.dart seeds realistic machine/correction/copy-marker/revision states and provides keyed bottom-sheet scrolling with an explicit vertical scrollable. Screen scrolling keeps the existing keyed outer-page helper. All sheet-opening tests pump the slide before interacting. New DB-backed editor tests await processor work before the existing pumpFuture database close.

## Floating navigation (redesign phase 2)

Tabs.finder supports three visible indices: notes=0, links=1, ask=2. Add is
Tabs.addButton (nav-add), never a tab index. All existing Add callers are updated.
The harness optionally accepts glassTier for deterministic frosted screenshots;
production automatic tier selection is unchanged. Existing DB/resource teardown
remains inside the test zone, with no new close-after-unmount awaits.

## Links library (redesign phase 3)

links_library_data supplies pure projection factories and the 5,000-note/9,998-pair diagnostic shared by the unit test and direct cached-Dart timing. links_library_fixture seeds a real app project with parent/child groups, topics, confirmed chains and three suggestions, supports localized screenshot content, exposes unique vertical scroll/segment/route helpers and LibrarySpy (per-operation gate/failure/call counts and a completion future). Tests own gates through addTearDown and wait for writes before teardown. No harness cleanup or native mocks change.

measureLargeLibrary is the exact diagnostic body called by links_index_test. It times the notes half, the links half (cold, and the median of five link-write re-runs) and one search. Latest host run: ~40 ms cold total (notes ~19 ms, links ~20 ms), ~8 ms per link write, ~4.5 ms search, for 5,000 notes and 9,998 pair rows producing 5,000 Browse rows and 4,999 suggestions. Projection creation is outside the timer. Direct Dart smoke assertions for dedupe/project/dismissal/count/search/cache rules passed; no Flutter suite result is claimed.
