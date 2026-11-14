# Voice to text tests

whisper_metrics_test.dart retains the standalone spike's RTF, one-line Unicode JSON, RTL detection, WAV header and six model URL tests. voice_text_logic_test.dart covers exact pre-download labels/headroom, ten-recording persistence/eviction/deletion, JSONL, no network on failed free-space check, bounded history and microphone lease release.

FakeVoiceTextBackend hands out amplitude and live-partial streams through testZoneStream: a broadcast subscription's cancel() returns a root-zone future that FakeAsync never completes, which would hang the controller's `await cancel()` on stop. It controls inventory, progress/completion, cancellation, recorder failures, held inference, run outcomes and live partials without plugins/network/disk. voice_text_fixture.dart hosts the actual screen with FIKRA's theme/localization and provides scrolling/tapping helpers. voice_text_screen_test.dart exercises empty/downloading/downloaded/recording/transcribing/result/live states, model reuse, AAC/language/advanced choices, delete confirmations, all typed errors, large text and reduced motion. VoicePlayer is real and lazy; existing audio-channel tests cover playback itself.

Run `flutter test test/voice_text`. Real Settings/router screenshots live in ../screenshots/voice_text_test.dart. No test implies device accuracy, codec or thermal/performance verification.

## Lazy scrolling and local model follow-up

All scrolling goes through revealVoiceText with a plain keyed target that can be empty until built. The outer Scrollable is selected explicitly by its ancestors; SelectableText's nested Scrollables are excluded. tapVoiceText, six-model size checks, base-model selection, result reveals and screenshot fixtures use the same helper. No first/last/at finder is passed as a scrolling target.

The fake inventory models absent, invalid and validated Egyptian files. Widget cases cover visibility, placement after the default, actual size, selection, no download/delete controls and the run filename. A file-level test applies the unchanged small Q5_1 header checks to a sparse fixture, rejects an F16 header, checks no remote URL and verifies the local run's model field.
