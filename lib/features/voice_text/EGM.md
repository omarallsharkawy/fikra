# Voice to text experiment — local settings, trials and saved-note adapter

Settings' Voice section pushes `/settings/voice-text` through the existing MaterialPage helper. Phase 1 adds persisted model/speech-language choices and the three-part trial layout. Phase 2 adds optional saved-note transcription through the data-layer queue; phase 3 adds user-consented external engines.

## Preferences and selection

`voice_text_preferences.dart` restores choices through the narrow VoiceTextSettings contract in data/settings_repository.dart. LocalSettingsRepository stores `voice_text_model` (modelName) and `voice_text_language` (ar/en/auto) in the existing settings table. These preferences need no migration; saved transcript columns arrive in schema v7. Wiping notes/projects keeps these preferences, just as it keeps theme and app language. UI language and speech language remain independent.

An installed saved model wins. Otherwise choose installed Egyptian, small, base, tiny in that order (quantised first within a family), or tiny-q5_1 if none are installed so its download is offered. The fallback is persisted immediately, replacing stale names. Explicit model/language changes await storage before publishing the new choice; failures remain visible and retain the old choice. Inventory refresh after deletion repairs a disappearing installed selection. No preference write is deferred to screen disposal.

## Screen and widgets

- User settings: intro, always-visible primary radio rows (Tiny, validated Egyptian when present, Medium, More accurate), total model storage and speech language. Each model row carries its own size/hint/status and download/delete/cancel actions. Downloads explicitly select and persist the target row before starting. The model sheet is removed.
- Try it: file recording, explicit transcription of the selected trial clip, live partials, and last trial transcript with elapsed seconds. Shared InlineRecorder and VoicePlayer behavior is preserved; this is not automatic transcription.
- For testing: collapsed by default with expanded semantics. It expands through AnimatedSize with FikraMotion.expand; under Reduce Motion it appears at once without AnimatedSize, because a zero-duration AnimatedSize re-dirties itself during its own layout (a debug assertion). Contains format, threads, inventory refresh, uncompressed variants, ten recent playable/deletable recordings, re-run and all five run-history entries with technical numbers. An active uncompressed model is promoted into the main list so no restored selection is hidden; other full variants stay here.

Every surface uses FikraScaffold, SolidSurface, Pressable, SheetOption/showFikraSheet, FikraButton/IconButton, the app confirmation dialog, badges, StatusBanner/showToast and existing tokens. The title/tag gap uses FikraSpace.s8. Error actions and asynchronous capture failures show a toast and scroll to the persistent error banner with existing motion tokens, including a static jump under reduced motion. After a long jump the lazy list corrects its offset by the newly inserted banner's height, so the jump repeats (at most twice) on the following frames until the list rests at the top. Millisecond values and their Latin unit use a non-breaking space and one direction isolate.

## Native/file boundaries

The fakeable VoiceTextBackend owns native recording, models and inference. Models stay in application support `fikra_whisper_spike/models`, recordings/index/JSONL in `fikra_whisper_spike/recordings`. File inference runs through whisper_ggml's isolate; live uses its worker. The shared microphone lease is claimed before permission/playback teardown and released after cleanup. File and live captures retain their 30-minute cap. Pop remains blocked during capture and uncancellable inference; download disposal cancels pending network work.

Six downloadable files retain their exact owner-supplied size labels. Downloads are confirmed with size/Wi-Fi advice, check Android free space with headroom, stream atomically to .part, validate length/header/quantisation and report interruptions. Validation is structural rather than cryptographic. No model is downloaded automatically.

`ggml-small-egy-cs-q5_1.bin` remains an optional local file with the normal small Q5_1 header validation and actual disk size. It has no download/delete controls. `FIKRA_WHISPER_DIR <absolute path>` prints once per native backend initialization. The testing area's refresh action replaces the old sheet's implicit rescan. Disappearing or invalid selected local files fall back and repair the preference.

Every local trial still prints one `FIKRA_WHISPER {json}` line and appends recordings/runs.jsonl. Remote trials keep only the visible in-memory history and never print or append text/audio/keys. Local-only model_url is null. FFmpeg conversion duration is separate; transcription-plus-load remains approximate; live startup and finalization are measured, and live RTF includes listening. RSS is whole-process and peak is lifetime maximum.

## Verification

`flutter analyze`; `flutter test test/voice_text`; `test/settings_test.dart`; AR/EN dark/light fixtures in test/screenshots/voice_text_test.dart. Tests fake preferences and native work, cover saved choices/fallback, row selection semantics, collapse/expand, visible errors, retained capture/re-run/live behavior and non-breaking units. The sandbox cannot run Flutter tests because localhost sockets are blocked. Native accuracy, memory, codecs, thermal costs and actual storage remain phone checks.

## Saved recording adapter and automation (phase 2)

The user settings part now includes VoiceTextAuto: existing SheetOption toggle icons, toggled/enabled semantics and a short local-work hint. It persists voice_text_auto_transcribe through VoiceTextSettings, defaults off and explains the required download when no model is installed. Turning off remains available if an enabled user's last model disappears. Model/language preferences are still independent and immediately saved.

LocalTranscriptionEngine implements the provider-neutral data interface, prepares the saved model without creating a recorder, and reuses SpikeModelStore validation + WhisperFileEngine for AAC conversion/isolate inference. Missing/invalid weights, unreadable/empty audio, busy timeout and other errors map to stable queue codes. It uses four threads and frees the model after every file call. No saved voice note is added to the ten trial recordings. Saved-note runs are private (`WhisperFileEngine.run(private: true)`): they print one FIKRA_WHISPER line with the numbers but `text: null` and `text_chars`, and append nothing to runs.jsonl, so a note's speech never reaches logcat or the experiment's history (which wiping data does not clear). Trial runs keep a text-redacted line and JSONL; conversion_failed distinguishes decoder failures from native inference failures.

The controller's capture methods now live in voice_text_capture.dart (part/extension) to keep files small. File trials, the entire live session and model deletion claim the same process-wide WhisperLock used by the saved-recording adapter. Trials decline immediately with vtEngineBusy; queued local jobs wait up to ten minutes. Lease lifetime covers real inference shutdown and disposal. FFmpeg decoder probing moved from screen initialization into lease-protected trial start so it cannot disturb another job's global FFmpeg session/timing. Microphone recording alone need not hold the model lease.

`transcription_service.dart`: `AndroidTranscriptionKeepAlive` implements the data layer's `TranscriptionKeepAlive` over MethodChannel `fikra/transcription_service` (see android/app/src/main/kotlin/com/fikra/app/EGM.md), sending the localized channel name (`trNotificationChannel`), title (`trWorking`) and count (`trNotificationLeft`); a false result (Android refused, app already in background) is logged and work continues. `TranscriptionNotificationPermission` / `PluginNotificationPermission` wrap permission_handler's notification permission (`canAsk` = status is denied but still askable).

## External service choice and forms (phase 3)

User settings begins with VoiceTextEngines: On your phone or any saved service, with selected semantics, edit controls and Add. The on-phone model list is visible only for local choice; speech language remains shared. Auto mode does not require a downloaded local model for a remote choice and its hint names the recipient. Intro text is destination-specific, and loading/error states never claim that files stay local before the service snapshot is known.

ServiceFormScreen (+ ServiceFormFields) uses FikraScaffold, FikraField, SheetOption/showFikraSheet, VoiceTextChoice, ChoiceTag region presets, existing buttons/icons, StatusBanner/toast, tokens and route motion. It edits name/type/base URL/model/optional language hint and an obscured key with accessible show/hide. Fixed providers show their actual URL read-only; OpenAI-compatible and Qwen URLs are editable, with Singapore/Beijing presets and an HTTP LAN warning. Blank key retains the stored credential only when type/origin are unchanged. No stored key is populated into a text field. Partial URLs remain safe while editing. Save/delete complete storage before allowing the route to pop; delete requires confirmation.

service_consent.dart uses the existing confirmation dialog, naming the service and URL, explicitly describing upload, possible retention/charges and unencrypted LAN transport where relevant. It is required before first external selection or probe. Consent is persisted per type/URL destination identity; editing that destination requires fresh agreement; renaming or changing a model does not. A stale dialog cannot authorize a different stored destination. A successful explicit probe may carry its agreement into Save, so later selection does not ask again.

Try it reads the current selected service, uses the same engine factory as the queue, and skips WhisperLock for remote requests. Remote results/measurements are UI-only and include attribution; raw provider errors are never retained. Existing trial native work still uses the lease. Live text is explicitly local-only and disabled for a remote engine; this phase implements file APIs, not remote streaming. voice_text_remote.dart keeps the controller near 300 lines.

Remote format rejection alone may use remote_audio_converter.dart: the existing bundled FFmpeg 16 kHz mono PCM path, quiet logs, arguments passed separately, a unique temp file and cleanup. Saved-note requests retain their keep-alive and crash-loop protection. No audio is sent merely by opening settings, saving a service, selecting an agreed service or enabling auto mode.

TranscriptionSource labels local models as before and remote IDs as Via <service alias>. Deleted-service aliases remain in non-secret settings until wipe; IDs do not encode model revisions. All visible text lives in ARB, including provider product labels.

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.

## Voice 2a model picker

The batch model field is now ServiceModelPicker: SheetOption opens the existing sheet, with Recommended/Other/Legacy groups, per-entry Arabic notes, exact legacy shutdown warnings, supported choices and a collapsed custom-ID field. Unsupported Gemini Transcribe is text only. Groq catalog filtering follows the base host; unknown discovered IDs are never offered. liveModel is retained but not shown. Refresh uses typed or origin-bound saved keys only after service consent, sends no audio, and shows cached account-availability and checked time; failure preserves model/cache and uses StatusBanner/toast. Form controls/navigation stay locked during refresh. The Qwen form explains why discovery is unavailable.

WhisperRun now redacts text and raw error strings for every diagnostic/JSONL run, including old local trials, to follow Voice 2a's no-transcript-logging rule. Text still appears in the in-memory UI result. Private saved-note runs still create no JSONL history.

## Ordering & IA (redesign phase 4)

`VoiceTextScreen` orders its `ListView` with `Semantics(header: true)` headings: intro (followed by `vt-error` and loading progress when present, keeping scroll-to-0 error visibility intact), everyday choices (`vsEngine`, `vtModel` when local, `vtLanguage`, `VoiceTextAuto`), a hairline divider, `vtTry` (`VoiceTextRecording`, `vt-try-transcribe`, `vtLive` with `vt-live`, and `vtResult` when present; `vtLive` and `vtResult` are `Semantics(header: true)` headings too), a hairline divider, and `vt-testing-toggle` (`For testing`, collapsed by default, immediate under `FikraMotion.reduced` without zero-duration `AnimatedSize`) at the bottom. No backend, storage or model behaviour changes.

## Motion & delight (redesign phase 7)

`VoiceTextRecording` wraps `vt-stop` in `RecordingPulse` (`vt-stop-pulse`) while recording; capture, storage and permission paths are unchanged.
