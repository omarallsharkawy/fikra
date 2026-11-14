# Voice to text experiment

Settings pushes `/settings/voice-text` through the app router's MaterialPage helper. This experiment has no note, attachment-saving or database integration. It uses FikraScaffold, Glass, SheetOption/showFikraSheet, FikraButton/IconButton, confirmDestructive, StatusBanner/showToast, InlineRecorder and VoicePlayer with existing tokens. UI strings come from vt* ARB keys; content direction follows the transcript.

## Boundaries

- voice_text_backend.dart: small fakeable boundary for files, downloads, recording and Whisper; typed UI errors and inventory.
- voice_text_controller.dart: serialized operations, five-run history, default tiny-q5_1/four threads/WAV/Arabic; no concurrent captures, downloads or inference. Providers connect the shared recordingActiveProvider lease; playback stops before capture, transcription and recording deletion.
- native_voice_text_backend.dart: record WAV PCM16 mono/16k or the app's AAC-LC mono/64k config. Application-support storage remains `fikra_whisper_spike/{models,recordings}` to preserve the first spike's files. Last ten recordings and JSONL persist; no automatic note transcription.
- whisper_file_engine.dart, whisper_live_engine.dart, whisper_run.dart: whisper_ggml modelPath inference and unchanged FIKRA_WHISPER JSON lines, also appended to recordings/runs.jsonl. One-shot conversion duration comes from FFmpeg; transcription-plus-load is explicitly approximate. Live startup/finalization are measured and live RTF includes listening. File inference stays in the package isolate; live uses the package worker.
- whisper_models.dart/whisper_metrics.dart/whisper_recordings.dart: reused pure/file helpers. Six owner-supplied size labels are exact. Download atomically streams to .part, supports cancellation/timeouts and validates length plus GGML header/quantisation; there is no cryptographic checksum. Stale partial downloads are reported and removed. Models are never automatically downloaded.

## Safety and lifecycle

Every download is confirmed with size/Wi-Fi advice, then checks Android free space through the read-only fikra/voice_text_storage channel. Headroom is 10% plus 16 MiB, retaining space for replacing an existing file. Real disk-full errors remain handled because the check cannot reserve space. Deleting a model or clip requires confirmation. Model and recording data are independent of notes and the database.

The shared microphone lease is claimed before awaiting permission and released after stop/cleanup. Normal recording and live sessions have a 30-minute cap. Pop is blocked during capture, startup/finalization and uncancellable one-shot inference; a download can be cancelled or cancelled on disposal. Dispose waits for in-flight work before recorder teardown and reports cleanup failures to the debug log. No app-wide recording or saving behavior changes.

## Verification

`flutter analyze`; `flutter test test/voice_text`; screenshot fixtures in test/screenshots/voice_text_test.dart cover the real Settings route plus empty, model picker, confirmation, recording and result in both locales/themes. Native audio, model loading, FFmpeg codec support, storage channel and phone costs require Android. No standalone entrypoint or lib/spike files remain.

## Local Egyptian model

`ggml-small-egy-cs-q5_1.bin` is an optional adb-supplied file in the same models directory. Inventory exposes it only after the existing small multilingual Q5_1 header/length validation passes; invalid files stay hidden and surface the existing corrupt-model warning. It appears directly after the default tiny-q5_1, uses its actual disk byte count through Fmt.bytes, and has no download/delete controls. The downloader rejects local-only models; model_url is null in their otherwise unchanged FIKRA_WHISPER run JSON. Result cards recognize the local filename.

The native backend creates the directory and prints `FIKRA_WHISPER_DIR <absolute models path>` once when the screen/backend initializes. Opening the picker rescans inventory, so an adb push is discoverable without reopening the screen. If a selected local file disappears or becomes invalid, the next inventory refresh restores the default model. Size units keep the app's existing Latin MB in Arabic.
