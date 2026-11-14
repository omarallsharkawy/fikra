import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:fikra/features/voice_text/voice_text_controller.dart';
import 'package:fikra/features/voice_text/whisper_recordings.dart';
import 'package:fikra/features/voice_text/whisper_run.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_voice_text_backend.dart';

void main() {
  test('every finished run prints one JSON line and appends the same line', () async {
    final dir = await Directory.systemTemp.createTemp('fikra-whisper-run');
    addTearDown(() => dir.delete(recursive: true));
    final store = RecordingStore(dir);
    final run = WhisperRun(spikeModels.first, 'ar', 4, 'wav_pcm16_16khz_mono', 12, 'file', {});
    run.values['text'] = 'فكرة\nكلام';
    final printed = <String>[];
    final result = await runZoned(
      () => run.finish(store),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => printed.add(line)),
    );
    expect(printed, hasLength(1));
    expect(printed.single.startsWith('FIKRA_WHISPER '), isTrue);
    expect(printed.single.split('\n'), hasLength(1));
    expect(jsonDecode(printed.single.substring(14)), result);
    expect(await File('${dir.path}/runs.jsonl').readAsLines(), printed);
  });

  test('a private note run prints its numbers without the text and keeps no history', () async {
    final dir = await Directory.systemTemp.createTemp('fikra-whisper-run');
    addTearDown(() => dir.delete(recursive: true));
    final run = WhisperRun(spikeModels.first, 'ar', 4, 'wav_pcm16_16khz_mono', 12, 'file', {});
    run.values['text'] = 'كلام خاص';
    final printed = <String>[];
    final result = await runZoned(
      () => run.finish(RecordingStore(dir), private: true),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => printed.add(line)),
    );
    expect(result['text'], 'كلام خاص');
    expect(printed, hasLength(1));
    expect(printed.single, isNot(contains('كلام')));
    final logged = jsonDecode(printed.single.substring(14)) as Map<String, Object?>;
    expect(logged['text'], isNull);
    expect(logged['text_chars'], 8);
    expect(logged['wall_ms'], result['wall_ms']);
    expect(await File('${dir.path}/runs.jsonl').exists(), isFalse);
  });

  test('local Egyptian model requires the existing small Q5_1 header validation', () async {
    final dir = await Directory.systemTemp.createTemp('fikra-egyptian-model');
    addTearDown(() => dir.delete(recursive: true));
    final store = SpikeModelStore(dir);
    expect(await store.validatedEgyptianBytes(), isNull);
    final header = ByteData(48);
    final values = [0x67676d6c, 51865, 1500, 768, 12, 12, 448, 768, 12, 12, 80, 2009];
    for (var i = 0; i < values.length; i++) {
      header.setInt32(i * 4, values[i], Endian.little);
    }
    final file = store.file(egyptianModel);
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeFrom(header.buffer.asUint8List());
      await handle.truncate(2 * 1024 * 1024);
    } finally {
      await handle.close();
    }
    expect(await store.validatedEgyptianBytes(), 2 * 1024 * 1024);
    final changed = await file.open(mode: FileMode.write);
    try {
      header.setInt32(44, 1, Endian.little); // F16 is not the advertised Q5_1.
      await changed.writeFrom(header.buffer.asUint8List());
      await changed.truncate(2 * 1024 * 1024);
    } finally {
      await changed.close();
    }
    await expectLater(store.validatedEgyptianBytes(), throwsFormatException);
    expect(file.path.endsWith('/ggml-small-egy-cs-q5_1.bin'), isTrue);
    expect(() => modelUrl(egyptianModel), throwsArgumentError);
    final run = WhisperRun(egyptianModel, 'ar', 4, 'wav_pcm16_16khz_mono', 12, 'file', {});
    expect(run.values['model'], 'ggml-small-egy-cs-q5_1.bin');
    expect(run.values['model_url'], isNull);
  });

  test('owner-supplied sizes are exact, ordered smallest first, with free-space headroom', () {
    expect(spikeModels.map((m) => m.downloadMb), ['30.7', '56.9', '181.3', '74.1', '141.1', '465.0']);
    for (final model in spikeModels) {
      expect(model.requiredFreeBytes, greaterThan(double.parse(model.downloadMb) * 1024 * 1024));
    }
  });

  test('recording store retains ten, removes evicted files and persists deletion', () async {
    final dir = await Directory.systemTemp.createTemp('fikra-voice-text-test');
    addTearDown(() => dir.delete(recursive: true));
    final store = RecordingStore(dir);
    var clips = <SpikeRecording>[];
    for (var i = 0; i < 11; i++) {
      final path = '${dir.path}/$i.wav';
      await File(path).writeAsBytes([0]);
      clips = await store.add(SpikeRecording(path, 'wav_pcm16_16khz_mono', 1), clips);
    }
    expect(clips, hasLength(10));
    expect(await File('${dir.path}/0.wav').exists(), isFalse);
    final removed = clips.first;
    clips = await store.remove(removed, clips);
    expect(await File(removed.path).exists(), isFalse);
    expect(await store.load(), hasLength(9));
    await store.appendRun('FIKRA_WHISPER {"text":"فكرة"}');
    expect(await File('${dir.path}/runs.jsonl').readAsLines(), ['FIKRA_WHISPER {"text":"فكرة"}']);
  });

  test('space failure prevents network and transcription history stays bounded', () async {
    final fake = FakeVoiceTextBackend()..spaceIssue = VoiceTextIssue.storage;
    final c = VoiceTextController(
      fake,
      settings: FakeVoiceTextSettings(),
      claimMicrophone: () => true,
      releaseMicrophone: () {},
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.download();
    expect(fake.downloads, 0);
    expect(c.issue, VoiceTextIssue.storage);
    fake.seed();
    await c.initialize();
    for (var i = 0; i < 7; i++) {
      await c.transcribe();
    }
    expect(c.history, hasLength(5));
  });

  test('permission denial and recorder failure release the microphone lease', () async {
    var claimed = false;
    final fake = FakeVoiceTextBackend()..recordIssue = VoiceTextIssue.permission;
    final c = VoiceTextController(
      fake,
      settings: FakeVoiceTextSettings(),
      claimMicrophone: () {
        claimed = true;
        return true;
      },
      releaseMicrophone: () {
        claimed = false;
      },
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.start();
    expect(c.issue, VoiceTextIssue.permission);
    expect(claimed, isFalse);
    fake.recordIssue = null;
    fake.stopIssue = VoiceTextIssue.empty;
    await c.start();
    expect(claimed, isTrue);
    await c.stop();
    expect(claimed, isFalse);
    expect(c.issue, VoiceTextIssue.empty);
  });
}
