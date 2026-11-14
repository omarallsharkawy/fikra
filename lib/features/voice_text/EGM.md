# Voice to text experiment — model choice and layout (phase 1)

Settings' Voice section pushes `/settings/voice-text` through the existing MaterialPage helper. This phase adds persisted model/speech-language choices and reorganizes the experiment. It does not transcribe saved voice notes, add external engines, or add auto-transcription. Only preferences use the database; notes and attachment saving are untouched.

## Preferences and selection

`voice_text_preferences.dart` restores choices through the narrow VoiceTextSettings contract in data/settings_repository.dart. LocalSettingsRepository stores `voice_text_model` (modelName) and `voice_text_language` (ar/en/auto) in the existing settings table. No schema migration is needed. Wiping notes/projects keeps these preferences, just as it keeps theme and app language. UI language and speech language remain independent.

An installed saved model wins. Otherwise choose installed Egyptian, small, base, tiny in that order (quantised first within a family), or tiny-q5_1 if none are installed so its download is offered. The fallback is persisted immediately, replacing stale names. Explicit model/language changes await storage before publishing the new choice; failures remain visible and retain the old choice. Inventory refresh after deletion repairs a disappearing installed selection. No preference write is deferred to screen disposal.

## Screen and widgets

- User settings: intro, always-visible primary radio rows (Tiny, validated Egyptian when present, Medium, More accurate), total model storage and speech language. Each model row carries its own size/hint/status and download/delete/cancel actions. Downloads explicitly select and persist the target row before starting. The model sheet is removed.
- Try it: file recording, explicit transcription of the selected trial clip, live partials, and last transcript with elapsed seconds. Shared InlineRecorder and VoicePlayer behavior is preserved; this is not automatic transcription.
- For testing: collapsed by default with expanded semantics. It expands through AnimatedSize with FikraMotion.expand; under Reduce Motion it appears at once without AnimatedSize, because a zero-duration AnimatedSize re-dirties itself during its own layout (a debug assertion). Contains format, threads, inventory refresh, uncompressed variants, ten recent playable/deletable recordings, re-run and all five run-history entries with technical numbers. An active uncompressed model is promoted into the main list so no restored selection is hidden; other full variants stay here.

Every surface uses FikraScaffold, Glass, Pressable, SheetOption/showFikraSheet, FikraButton/IconButton, the app confirmation dialog, badges, StatusBanner/showToast and existing tokens. The title/tag gap uses FikraSpace.s8. Error actions and asynchronous capture failures show a toast and scroll to the persistent error banner with existing motion tokens, including a static jump under reduced motion. After a long jump the lazy list corrects its offset by the newly inserted banner's height, so the jump repeats (at most twice) on the following frames until the list rests at the top. Millisecond values and their Latin unit use a non-breaking space and one direction isolate.

## Native/file boundaries

The fakeable VoiceTextBackend owns native recording, models and inference. Models stay in application support `fikra_whisper_spike/models`, recordings/index/JSONL in `fikra_whisper_spike/recordings`. File inference runs through whisper_ggml's isolate; live uses its worker. The shared microphone lease is claimed before permission/playback teardown and released after cleanup. File and live captures retain their 30-minute cap. Pop remains blocked during capture and uncancellable inference; download disposal cancels pending network work.

Six downloadable files retain their exact owner-supplied size labels. Downloads are confirmed with size/Wi-Fi advice, check Android free space with headroom, stream atomically to .part, validate length/header/quantisation and report interruptions. Validation is structural rather than cryptographic. No model is downloaded automatically.

`ggml-small-egy-cs-q5_1.bin` remains an optional local file with the normal small Q5_1 header validation and actual disk size. It has no download/delete controls. `FIKRA_WHISPER_DIR <absolute path>` prints once per native backend initialization. The testing area's refresh action replaces the old sheet's implicit rescan. Disappearing or invalid selected local files fall back and repair the preference.

Every run still prints one `FIKRA_WHISPER {json}` line and appends recordings/runs.jsonl. Local-only model_url is null. FFmpeg conversion duration is separate; transcription-plus-load remains approximate; live startup and finalization are measured, and live RTF includes listening. RSS is whole-process and peak is lifetime maximum.

## Verification

`flutter analyze`; `flutter test test/voice_text`; `test/settings_test.dart`; AR/EN dark/light fixtures in test/screenshots/voice_text_test.dart. Tests fake preferences and native work, cover saved choices/fallback, row selection semantics, collapse/expand, visible errors, retained capture/re-run/live behavior and non-breaking units. The sandbox cannot run Flutter tests because localhost sockets are blocked. Native accuracy, memory, codecs, thermal costs and actual storage remain phone checks.
