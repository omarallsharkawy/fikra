import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../processing/transcription_engine.dart';
import '../ids.dart';
import 'remote_builders.dart';
import 'remote_request.dart';
import 'remote_transport.dart';
import 'service_config.dart';

class ConvertedUpload {
  const ConvertedUpload(this.audio, this.remove);
  final AudioUpload audio;
  final Future<void> Function() remove;
}

typedef AudioFormatFallback = Future<ConvertedUpload> Function(AudioUpload original);

class RemoteTranscriptionEngine implements TranscriptionEngine {
  RemoteTranscriptionEngine(this.service, this.readKey, this.transport, {this.convert});
  final TranscriptionService service;
  final Future<String?> Function(String id) readKey;
  final TranscriptionTransport transport;
  final AudioFormatFallback? convert;
  @override
  String get id => service.engineId;

  @override
  Future<String> transcribe(String audioPath, {required String language}) async {
    _consent(); // Before opening the recording or reading a credential.
    try {
      return await upload(await AudioUpload.open(audioPath), language: language);
    } on TranscriptionFailure {
      rethrow;
    } on FileSystemException {
      throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
    }
  }

  void _consent() {
    if (!service.consented) throw const TranscriptionFailure(TranscriptionFailureReason.consentRequired);
  }

  Future<String> upload(AudioUpload audio, {required String language, bool connectionTest = false}) async {
    _consent();
    service.validate();
    final clock = Stopwatch()..start();
    final timeout = remoteTimeout(audio.length);
    ConvertedUpload? converted;
    try {
      final key = await readKey(service.id);
      if (key == null || key.trim().isEmpty || RegExp(r'[\r\n]').hasMatch(key)) {
        throw const TranscriptionFailure(TranscriptionFailureReason.keyRejected);
      }
      var source = audio;
      for (var attempt = 0; attempt < 2; attempt++) {
        checkRemoteSize(service.type, source.length);
        final request = await buildTranscriptionRequest(service, key, source, language, boundary: 'fikra-${newId()}');
        if ((service.type == TranscriptionServiceType.gemini && request.contentLength > 20000000)) {
          throw const TranscriptionFailure(TranscriptionFailureReason.tooLarge);
        }
        final remaining = timeout - clock.elapsed;
        if (remaining <= Duration.zero) throw const TranscriptionFailure(TranscriptionFailureReason.remoteTimeout);
        final response = await transport.send(request, timeout: remaining);
        if (response.status >= 200 && response.status < 300) {
          if (connectionTest) {
            // A short silence clip can produce no text (or no transcript JSON).
            // A 2xx still verifies that this endpoint accepted the request.
            try {
              return parseTranscriptionResponse(service.type, response.body);
            } on TranscriptionFailure {
              return '';
            }
          }
          final text = parseTranscriptionResponse(service.type, response.body);
          if (text.isEmpty) throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
          return text;
        }
        if (attempt == 0 &&
            rejectedAudioFormat(response) &&
            convert != null &&
            source.path != null &&
            source.mime != 'audio/wav') {
          converted = await convert!(source);
          source = converted.audio;
          continue;
        }
        throw TranscriptionFailure(responseFailure(response));
      }
      throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    } on TranscriptionFailure {
      rethrow;
    } on ServiceConfigException catch (error) {
      throw TranscriptionFailure(
        error.issue == ServiceConfigIssue.consentRequired
            ? TranscriptionFailureReason.consentRequired
            : TranscriptionFailureReason.unexpectedResponse,
      );
    } on TimeoutException {
      throw const TranscriptionFailure(TranscriptionFailureReason.remoteTimeout);
    } on SocketException {
      throw const TranscriptionFailure(TranscriptionFailureReason.offline);
    } on FileSystemException {
      throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
    } catch (_) {
      // Discard all raw exception text, including echoed credentials/bodies.
      throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    } finally {
      if (converted != null) {
        // A leftover temp file must not turn a finished transcript into a failure.
        try {
          await converted.remove();
        } catch (_) {}
      }
    }
  }
}

Duration remoteTimeout(int bytes) => Duration(seconds: (60 + (bytes * 30 / (1024 * 1024)).ceil()).clamp(60, 600));

void checkRemoteSize(TranscriptionServiceType type, int bytes) {
  if (bytes <= 0) throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
  final encoded = ((bytes + 2) ~/ 3) * 4;
  final tooLarge = switch (type) {
    TranscriptionServiceType.openAi => bytes > 25000000,
    TranscriptionServiceType.gemini => encoded + 16384 > 20000000,
    TranscriptionServiceType.qwen => encoded + 128 > 10000000,
    TranscriptionServiceType.elevenLabs => bytes >= 5000000000,
  };
  if (tooLarge) throw const TranscriptionFailure(TranscriptionFailureReason.tooLarge);
}

/// Bundled as code so no asset/pubspec change is needed: one second, 16 kHz
/// mono PCM silence, 32,044 bytes. Never reads or uploads a user's recording.
AudioUpload connectionTestClip() {
  final bytes = Uint8List(32044);
  final data = ByteData.sublistView(bytes);
  for (final entry in [(0, 'RIFF'), (8, 'WAVE'), (12, 'fmt '), (36, 'data')]) {
    bytes.setRange(entry.$1, entry.$1 + 4, entry.$2.codeUnits);
  }
  data.setUint32(4, bytes.length - 8, Endian.little);
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  data.setUint32(40, 32000, Endian.little);
  return AudioUpload(name: 'connection.wav', length: bytes.length, bytes: bytes);
}
