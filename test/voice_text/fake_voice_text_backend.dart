import 'dart:async';

import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:fikra/data/settings_repository.dart';

Map<String, Object?> sampleVoiceTextRun({bool arabic = true, bool live = false, VoiceTextIssue? issue}) => {
  'timestamp': '2026-11-14T12:00:00.000Z',
  'mode': live ? 'live' : 'file',
  'model': 'ggml-tiny-q5_1.bin',
  'language': arabic ? 'ar' : 'en',
  'threads': 4,
  'source_format': live ? 'live_pcm16_16khz_mono' : 'wav_pcm16_16khz_mono',
  'audio_seconds': 12.0,
  'wall_ms': 4000,
  'rtf': 1 / 3,
  'conversion_ms': live ? null : 60,
  'transcription_wall_ms_estimate': live ? null : 3940,
  'model_load_ms': live ? 320 : null,
  'rss_before_mb': 84.0,
  'rss_after_mb': 146.0,
  'rss_max_mb': 218.0,
  'text': issue == null
      ? (arabic ? 'بكرة هكتب أفكاري بعد الشغل.' : 'Tomorrow I will write down my ideas after work.')
      : '',
  'error': issue == null ? null : 'native test failure',
  'error_kind': issue?.name,
};

/// A broadcast subscription's cancel() returns the SDK's root-zone null future,
/// which FakeAsync never completes, so `await subscription.cancel()` in the
/// controller would hang every widget test. Real plugin streams have no such
/// zone split. Each listener gets its own controller whose cancel future
/// belongs to the test zone.
Stream<T> testZoneStream<T>(Stream<T> source) {
  StreamSubscription<T>? inner;
  late final StreamController<T> out;
  out = StreamController<T>(
    onListen: () => inner = source.listen(out.add, onError: out.addError, onDone: out.close),
    onCancel: () async => unawaited(inner?.cancel()),
  );
  return out.stream;
}

class FakeVoiceTextBackend implements VoiceTextBackend {
  Map<String, int> sizes = {};
  List<SpikeRecording> clips = [];
  VoiceTextIssue? loadIssue, spaceIssue, downloadIssue, recordIssue, stopIssue, runIssue;
  Completer<void>? downloadGate;
  Completer<Map<String, Object?>>? runGate;
  final amplitudes = StreamController<double>.broadcast();
  bool cancelled = false;
  bool aac = false;
  bool arabic = true;
  bool disposed = false;
  bool egyptianFilePresent = false;
  bool egyptianFileValid = true;
  int egyptianBytes = 190000000;
  int downloads = 0;
  int transcriptions = 0;
  String? lastModel, lastLanguage;
  int? lastThreads;
  FakeVoiceTextLive? live;

  void seed() {
    sizes[spikeModels.first.modelName] = 32191283;
    clips = [const SpikeRecording('/private/test.wav', 'wav_pcm16_16khz_mono', 12)];
  }

  void _check(VoiceTextIssue? issue) {
    if (issue != null) throw VoiceTextFailure(issue);
  }

  @override
  Future<VoiceTextInventory> load() async {
    _check(loadIssue);
    final visibleSizes = Map.of(sizes);
    if (egyptianFilePresent && egyptianFileValid) visibleSizes[egyptianModel.modelName] = egyptianBytes;
    return VoiceTextInventory(sizes: visibleSizes, recordings: List.of(clips));
  }

  @override
  Future<void> checkSpace(SpikeModel model) async => _check(spaceIssue);
  @override
  Future<void> download(SpikeModel model, void Function(int, int) progress) async {
    downloads++;
    cancelled = false;
    _check(downloadIssue);
    progress(25, 100);
    await downloadGate?.future;
    if (cancelled) throw const VoiceTextFailure(VoiceTextIssue.cancelled);
    sizes[model.modelName] = 32191283;
    progress(100, 100);
  }

  @override
  void cancelDownload() {
    cancelled = true;
    if (downloadGate != null && !downloadGate!.isCompleted) downloadGate!.complete();
  }

  @override
  Future<void> deleteModel(SpikeModel model) async {
    sizes.remove(model.modelName);
  }

  @override
  Future<void> deleteRecording(SpikeRecording clip) async {
    clips.removeWhere((c) => c.path == clip.path);
  }

  @override
  Stream<double> get amplitudeDb => testZoneStream(amplitudes.stream);
  @override
  Future<void> startRecording(bool aac) async {
    _check(recordIssue);
    this.aac = aac;
  }

  @override
  Future<void> stopRecording() async {
    _check(stopIssue);
    clips.insert(
      0,
      SpikeRecording(
        '/private/recording_${clips.length}.${aac ? 'm4a' : 'wav'}',
        aac ? 'aac_lc_m4a_64k_mono' : 'wav_pcm16_16khz_mono',
        8,
      ),
    );
  }

  @override
  Future<void> cancelRecording() async {}
  @override
  Future<Map<String, Object?>> transcribe(SpikeModel model, SpikeRecording clip, String language, int threads) async {
    transcriptions++;
    lastModel = model.filename;
    lastLanguage = language;
    lastThreads = threads;
    final run = runGate != null ? await runGate!.future : sampleVoiceTextRun(arabic: arabic, issue: runIssue);
    return {...run, 'model': model.filename, 'model_bytes': model.localOnly ? egyptianBytes : sizes[model.modelName]};
  }

  @override
  Future<VoiceTextLive> startLive(SpikeModel model, String language, int threads) async {
    _check(recordIssue);
    return live = FakeVoiceTextLive();
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    // Teardown must not await a stream after its widget listener is gone.
    unawaited(amplitudes.close());
    final active = live;
    if (active != null) unawaited(active.close());
  }
}

class FakeVoiceTextLive implements VoiceTextLive {
  final texts = StreamController<String>.broadcast();
  @override
  Stream<String> get partials => testZoneStream(texts.stream);
  @override
  Future<Map<String, Object?>> stop() async => sampleVoiceTextRun(live: true);
  Future<void> close() => texts.close();
}

/// Same narrow read/write contract as the database-backed settings repository.
class FakeVoiceTextSettings implements VoiceTextSettings {
  FakeVoiceTextSettings({this.modelName, this.language});
  String? modelName;
  String? language;
  @override
  Future<({String? modelName, String? language})> readVoiceTextChoices() async =>
      (modelName: modelName, language: language);
  @override
  Future<void> setVoiceTextModel(String value) async {
    modelName = value;
  }

  @override
  Future<void> setVoiceTextLanguage(String value) async {
    if (!const ['ar', 'en', 'auto'].contains(value)) throw ArgumentError.value(value);
    language = value;
  }
}
