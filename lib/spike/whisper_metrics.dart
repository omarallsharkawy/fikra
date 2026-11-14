import 'dart:convert';
import 'dart:typed_data';

double? realTimeFactor(int wallMs, double audioSeconds) =>
    audioSeconds > 0 && audioSeconds.isFinite ? wallMs / 1000 / audioSeconds : null;

double memoryMb(int bytes) => bytes / (1024 * 1024);

/// JSON escapes line breaks in transcripts, so every result stays on one line.
String whisperLogLine(Map<String, Object?> result) => 'FIKRA_WHISPER ${jsonEncode(result)}';

bool containsArabic(String text) => RegExp(r'[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff]').hasMatch(text);

class WavInfo {
  const WavInfo(this.dataBytes);

  final int dataBytes;
  double get seconds => dataBytes / 32000;
}

/// Reads a RIFF header prefix; the PCM payload need not be resident in Dart.
/// Record's WAV encoder and the spike converter both produce PCM16 mono/16k.
WavInfo parseWavHeader(Uint8List prefix, int fileLength) {
  final bytes = ByteData.sublistView(prefix);
  String tag(int offset) => String.fromCharCodes(prefix.sublist(offset, offset + 4));
  if (prefix.length < 12 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw const FormatException('Not a RIFF/WAVE recording');
  }
  if (bytes.getUint32(4, Endian.little) + 8 > fileLength) {
    throw const FormatException('Truncated WAV recording');
  }
  var validFormat = false;
  for (var offset = 12; offset + 8 <= prefix.length;) {
    final kind = tag(offset);
    final size = bytes.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (start + size > fileLength) throw const FormatException('Truncated WAV chunk');
    if (kind == 'fmt ') {
      if (size < 16 || start + 16 > prefix.length) throw const FormatException('Invalid WAV fmt chunk');
      validFormat =
          bytes.getUint16(start, Endian.little) == 1 &&
          bytes.getUint16(start + 2, Endian.little) == 1 &&
          bytes.getUint32(start + 4, Endian.little) == 16000 &&
          bytes.getUint32(start + 8, Endian.little) == 32000 &&
          bytes.getUint16(start + 12, Endian.little) == 2 &&
          bytes.getUint16(start + 14, Endian.little) == 16;
    } else if (kind == 'data') {
      if (!validFormat) throw const FormatException('Expected 16 kHz mono PCM16 WAV');
      if (size == 0) throw const FormatException('Empty recording: record some speech and retry');
      if (size.isOdd) throw const FormatException('Incomplete PCM16 sample');
      return WavInfo(size);
    }
    offset = start + size + (size & 1);
  }
  throw const FormatException('No WAV data header within the first 64 KiB');
}
