import 'dart:convert';
import 'dart:typed_data';

import 'package:fikra/features/voice_text/whisper_metrics.dart';
import 'package:fikra/features/voice_text/whisper_models.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List wavHeader({int dataBytes = 64000, int sampleRate = 16000}) {
  final header = Uint8List(44);
  final data = ByteData.sublistView(header);
  void tag(int offset, String value) => header.setRange(offset, offset + 4, value.codeUnits);
  tag(0, 'RIFF');
  data.setUint32(4, 36 + dataBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, dataBytes, Endian.little);
  return header;
}

void main() {
  test('RTF uses seconds and avoids zero/non-finite durations', () {
    expect(realTimeFactor(2500, 10), 0.25);
    expect(realTimeFactor(2500, 0), isNull);
    expect(realTimeFactor(2500, double.nan), isNull);
    expect(realTimeFactor(2500, double.infinity), isNull);
    expect(memoryMb(1048576), 1);
  });

  test('Arabic and multiline text survive one-line JSON logging', () {
    final result = {'text': 'فكرة جديدة\nEnglish "quote"', 'error': null, 'rtf': 0.25};
    final line = whisperLogLine(result);
    expect(line.split('\n'), hasLength(1));
    expect(line.startsWith('FIKRA_WHISPER '), isTrue);
    expect(jsonDecode(line.substring('FIKRA_WHISPER '.length)), result);
    expect(containsArabic(result['text']! as String), isTrue);
    expect(containsArabic('English'), isFalse);
  });

  test('WAV duration uses data chunk, without loading audio payload', () {
    expect(parseWavHeader(wavHeader(), 64044).seconds, 2);
  });

  test('WAV parser rejects empty, truncated and wrong-rate recordings', () {
    expect(() => parseWavHeader(wavHeader(dataBytes: 0), 44), throwsFormatException);
    expect(() => parseWavHeader(wavHeader(), 60000), throwsFormatException);
    expect(() => parseWavHeader(wavHeader(sampleRate: 44100), 64044), throwsFormatException);
    expect(() => parseWavHeader(Uint8List(4), 4), throwsFormatException);
  });

  test('WAV parser skips padded metadata chunks emitted by encoders', () {
    final original = wavHeader();
    final extended = Uint8List(54);
    extended.setRange(0, 36, original);
    extended.setRange(36, 40, 'JUNK'.codeUnits);
    final bytes = ByteData.sublistView(extended);
    bytes.setUint32(40, 1, Endian.little);
    extended[44] = 42; // odd chunk, followed by padding at 45
    extended.setRange(46, 54, original.sublist(36));
    bytes.setUint32(4, 64046, Endian.little);
    expect(parseWavHeader(extended, 64054).seconds, 2);
  });

  test('six multilingual model URLs include the required q5_1 filenames', () {
    expect(spikeModels, hasLength(6));
    expect(spikeModels.map((m) => m.filename).toSet(), {
      'ggml-tiny.bin',
      'ggml-tiny-q5_1.bin',
      'ggml-base.bin',
      'ggml-base-q5_1.bin',
      'ggml-small.bin',
      'ggml-small-q5_1.bin',
    });
    expect(modelUrl(spikeModels.first), 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin');
  });
}
