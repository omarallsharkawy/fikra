# Voice to text tests

whisper_metrics_test.dart retains RTF, one-line Unicode JSON, direction detection, WAV and model URL checks. voice_text_logic_test.dart covers JSONL, local-model header validation, exact size/headroom labels, ten-recording storage and deletion, no network on failed space checks, bounded history and microphone release.

voice_text_preferences_test.dart covers stored installed-model restoration, speech language, Egyptian default, Egyptian→small→base→tiny→Tiny-download fallback, immediate writes/reopening and preference repair after deletion. Settings database integration, unknown speech-language rejection and wipe retention are covered in ../settings_test.dart.

FakeVoiceTextBackend controls inventory/download/capture/inference/live boundaries; FakeVoiceTextSettings implements the production read/write contract in memory. Fake disposal is idempotent and does not await stream.close after widget listeners disappear. Controllers use addTearDown; fixture backends register teardown too. SemanticsHandles are the exception: testWidgets checks them before tearDowns run, so tests dispose them in the body. SelectableText is found with a widget predicate, since find.text matches its inner EditableText. No network/native call is made.

voice_text_screen_test.dart checks always-visible primary model rows and per-row controls, retained full variants, actual local-model size/visibility/default selection, selected semantics and persisted changes, collapsed/expanded testing semantics, recording/playback/delete/re-run, format/threads, everyday results versus raw history, non-breaking units, error scrolling after bottom actions, live partials and large text/reduced motion.

All scrolling uses revealVoiceText/tapVoiceText with a plain keyed target and explicit outer Scrollable, excluding SelectableText's nested Scrollable. No first/last/at finder is passed into scrollUntilVisible, ensureVisible or dragUntilVisible. The testing expansion helper opens the hidden measurement controls before selecting them.

Run flutter test test/voice_text; screenshots are in ../screenshots/voice_text_test.dart. The sandbox cannot run the Flutter runner's localhost socket. Tests do not establish phone recognition quality or native performance.

Phase 2 FakeVoiceTextSettings mirrors readAutoTranscribe/setAutoTranscribe with a false default. Trial controller tests share an injectable WhisperLock with saved-recording fake engines; capture methods remain imported through the controller library's part extension. No fake invokes native Whisper.

Phase 3 the standalone fixture overrides TranscriptionServices with an owned in-memory fake and registers its stream cleanup with addTearDown. Existing local trial tests remain isolated from Drift, secure storage and network while the screen adds engine selection. Remote trial/queue selection is covered in transcription_engine_selection_test, without native inference.

## Voice 2a diagnostic privacy

voice_text_logic_test now expects every local trial log/JSONL to contain text=null and text_chars, while the returned in-memory result retains its text. Saved-note private runs still omit history entirely. Raw error strings are excluded from diagnostics as well.
