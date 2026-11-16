import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../processing/transcription_engine.dart';
import 'remote_request.dart';
import 'service_config.dart';

abstract interface class TranscriptionTransport {
  Future<RemoteResponse> send(RemoteRequest request, {required Duration timeout});
}

class HttpTranscriptionTransport implements TranscriptionTransport {
  const HttpTranscriptionTransport();
  @override
  Future<RemoteResponse> send(RemoteRequest request, {required Duration timeout}) async {
    if (!validServiceUrl(request.uri)) throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      return await (() async {
        final upload = await client.postUrl(request.uri);
        // Never forward an API key or audio to an unconsented redirect target.
        upload.followRedirects = false;
        request.headers.forEach(upload.headers.set);
        upload.contentLength = request.contentLength;
        await upload.addStream(request.body());
        final response = await upload.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 1024 * 1024) {
            throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
          }
          bytes.addAll(chunk);
        }
        return RemoteResponse(response.statusCode, utf8.decode(bytes));
      })().timeout(timeout);
    } on TranscriptionFailure {
      rethrow;
    } on TimeoutException {
      throw const TranscriptionFailure(TranscriptionFailureReason.remoteTimeout);
    } on SocketException {
      throw const TranscriptionFailure(TranscriptionFailureReason.offline);
    } on HandshakeException {
      throw const TranscriptionFailure(TranscriptionFailureReason.offline);
    } catch (_) {
      throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    } finally {
      client.close(force: true); // Total timeout aborts upload and response too.
    }
  }
}
