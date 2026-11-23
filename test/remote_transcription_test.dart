import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/transcription/remote_builders.dart';
import 'package:fikra/data/transcription/remote_engine.dart';
import 'package:fikra/data/transcription/remote_request.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  final audio = AudioUpload(name: 'original.m4a', length: bytes.length, bytes: bytes);
  const key = 'SYNTHETIC_SECRET_KEY';
  Future<String> body(RemoteRequest request) async => utf8.decode(await request.body().expand((b) => b).toList());

  test('OpenAI compatible multipart: endpoint, auth, file/model/language and legacy model IDs', () async {
    // https://developers.openai.com/api/docs/guides/speech-to-text
    for (final model in ['gpt-4o-transcribe', 'gpt-4o-mini-transcribe', 'whisper-1']) {
      final s = TranscriptionService(
        id: 'openai',
        type: TranscriptionServiceType.openAi,
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1/',
        model: model,
      );
      final request = await buildTranscriptionRequest(s, key, audio, 'ar');
      expect(request.uri.toString(), 'https://api.openai.com/v1/audio/transcriptions');
      expect(request.headers['Authorization'], 'Bearer $key');
      expect(request.fields, {'model': model, 'language': 'ar', 'response_format': 'json'});
      expect(request.audio, same(audio));
      final encoded = await request.body().expand((b) => b).toList();
      expect(encoded, containsAllInOrder(bytes));
      expect(utf8.decode(encoded), contains('name="file"; filename="recording.m4a"'));
      expect(encoded.length, request.contentLength);
    }
    final generic = sampleService(url: 'https://api.groq.com/openai/v1');
    final request = await buildTranscriptionRequest(generic, key, audio, 'auto');
    expect(request.uri.path, '/openai/v1/audio/transcriptions');
    expect(request.fields.containsKey('language'), isFalse);
    final current = await buildTranscriptionRequest(sampleService(), key, audio, 'en');
    expect(current.fields['languages[]'], 'en');
  });

  test('Gemini inline original M4A, verbatim-only prompt and x-goog-api-key', () async {
    // https://aistudio.google.com/api-reference/generate-content
    // https://aistudio.google.com/docs/audio
    final service = sampleService(type: TranscriptionServiceType.gemini, language: 'ar');
    final request = await buildTranscriptionRequest(service, key, audio, 'en');
    expect(
      request.uri.toString(),
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent',
    );
    expect(request.headers['x-goog-api-key'], key);
    expect(request.uri.query, isEmpty);
    final parts = ((request.json!['contents'] as List).single as Map)['parts'] as List;
    expect((parts[1] as Map)['inlineData'], {'mimeType': 'audio/m4a', 'data': base64Encode(bytes)});
    expect((parts[0] as Map)['text'], contains('verbatim'));
    expect((parts[0] as Map)['text'], contains('Language hint: ar'));
  });

  test('ElevenLabs multipart fields and original AAC container', () async {
    // https://elevenlabs.io/docs/api-reference/speech-to-text/convert
    final request = await buildTranscriptionRequest(
      sampleService(type: TranscriptionServiceType.elevenLabs),
      key,
      audio,
      'ar',
    );
    expect(request.uri.toString(), 'https://api.elevenlabs.io/v1/speech-to-text');
    expect(request.headers['xi-api-key'], key);
    expect(request.fields['model_id'], 'scribe_v3');
    expect(request.fields['language_code'], 'ar');
    expect(request.fields['diarize'], 'false');
    expect(request.fields['tag_audio_events'], 'false');
    expect(await body(request), contains('Content-Type: audio/mp4'));
  });

  test('Qwen international/mainland and workspace URLs use audio chat completions', () async {
    // https://help.aliyun.com/en/model-studio/qwen-asr-api-reference
    for (final url in [
      qwenInternationalUrl,
      qwenMainlandUrl,
      'https://workspace.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1',
      'https://workspace.cn-beijing.maas.aliyuncs.com/compatible-mode/v1',
    ]) {
      final request = await buildTranscriptionRequest(
        sampleService(type: TranscriptionServiceType.qwen, url: url),
        key,
        audio,
        'en',
      );
      expect(request.uri.toString(), '$url/chat/completions');
      expect(request.headers['Authorization'], 'Bearer $key');
      expect(request.json!['asr_options'], {'enable_itn': false, 'language': 'en'});
      expect(request.json!['stream'], false);
      final content = ((request.json!['messages'] as List).single as Map)['content'] as List;
      expect(content.single, {
        'type': 'input_audio',
        'input_audio': {'data': 'data:audio/mp4;base64,${base64Encode(bytes)}'},
      });
    }
  });

  test('parses each documented response and excludes Gemini thinking parts', () {
    expect(parseTranscriptionResponse(TranscriptionServiceType.openAi, '{"text":"spoken"}'), 'spoken');
    expect(parseTranscriptionResponse(TranscriptionServiceType.elevenLabs, '{"text":"spoken"}'), 'spoken');
    expect(
      parseTranscriptionResponse(
        TranscriptionServiceType.qwen,
        '{"choices":[{"message":{"content":"spoken"},"finish_reason":"stop"}]}',
      ),
      'spoken',
    );
    expect(
      parseTranscriptionResponse(
        TranscriptionServiceType.gemini,
        '{"candidates":[{"finishReason":"STOP","content":{"parts":[{"thought":true,"text":"hidden"},{"text":"spoken"}]}}]}',
      ),
      'spoken',
    );
    for (final type in TranscriptionServiceType.values) {
      for (final value in ['not json $key', '{}', '[]']) {
        expect(
          () => parseTranscriptionResponse(type, value),
          throwsA(
            isA<TranscriptionFailure>()
                .having((e) => e.reason, 'reason', TranscriptionFailureReason.unexpectedResponse)
                .having((e) => e.toString().contains(key), 'no secret', isFalse),
          ),
        );
      }
    }
  });

  for (final entry in {
    401: TranscriptionFailureReason.keyRejected,
    403: TranscriptionFailureReason.keyRejected,
    429: TranscriptionFailureReason.rateLimited,
    413: TranscriptionFailureReason.tooLarge,
    500: TranscriptionFailureReason.serviceError,
    503: TranscriptionFailureReason.serviceError,
    302: TranscriptionFailureReason.unexpectedResponse,
  }.entries) {
    test('status ${entry.key} maps without retaining echoed secrets', () async {
      final transport = FakeTranscriptionTransport()..response = RemoteResponse(entry.key, '{"error":"$key"}');
      final engine = RemoteTranscriptionEngine(sampleService(consent: true), (_) async => key, transport);
      await expectLater(
        engine.upload(audio, language: 'ar'),
        throwsA(
          isA<TranscriptionFailure>()
              .having((e) => e.reason, 'reason', entry.value)
              .having((e) => e.toString().contains(key), 'no secret', isFalse),
        ),
      );
    });
  }

  for (final error in [const SocketException(key), TimeoutException(key), StateError(key)]) {
    test('transport ${error.runtimeType} is sanitized and mapped', () async {
      final transport = FakeTranscriptionTransport()..action = (_) async => throw error;
      final engine = RemoteTranscriptionEngine(sampleService(consent: true), (_) async => key, transport);
      await expectLater(
        engine.upload(audio, language: 'auto'),
        throwsA(
          isA<TranscriptionFailure>()
              .having(
                (e) => e.reason,
                'reason',
                error is SocketException
                    ? TranscriptionFailureReason.offline
                    : error is TimeoutException
                    ? TranscriptionFailureReason.remoteTimeout
                    : TranscriptionFailureReason.unexpectedResponse,
              )
              .having((e) => e.toString().contains(key), 'no secret', isFalse),
        ),
      );
    });
  }

  test('consent precedes key/audio access; probe accepts 2xx silence; no prints', () async {
    final keys = MemoryServiceKeys();
    final transport = FakeTranscriptionTransport();
    final denied = RemoteTranscriptionEngine(sampleService(), keys.read, transport);
    await expectLater(
      denied.transcribe('/must-not-be-read.m4a', language: 'ar'),
      throwsA(
        isA<TranscriptionFailure>().having((e) => e.reason, 'reason', TranscriptionFailureReason.consentRequired),
      ),
    );
    expect(keys.reads, 0);
    expect(transport.requests, isEmpty);
    final s = sampleService(consent: true);
    keys.values[s.id] = key;
    transport.response = const RemoteResponse(204, '');
    final engine = RemoteTranscriptionEngine(s, keys.read, transport);
    final prints = <String>[];
    final result = await runZoned(
      () => engine.upload(connectionTestClip(), language: 'auto', connectionTest: true),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => prints.add(line)),
    );
    expect(result, isEmpty);
    expect(prints, isEmpty);
    expect(connectionTestClip().length, 32044);
    expect(remoteTimeout(1), const Duration(seconds: 61));
    expect(remoteTimeout(1000000000), const Duration(minutes: 10));
  });

  test('size limits account for inline base64 overhead before any request', () async {
    for (final type in TranscriptionServiceType.values) {
      final transport = FakeTranscriptionTransport();
      final huge = AudioUpload(
        name: 'big.m4a',
        length: type == TranscriptionServiceType.elevenLabs ? 5000000000 : 30000000,
        bytes: Uint8List(0),
      );
      final engine = RemoteTranscriptionEngine(sampleService(type: type, consent: true), (_) async => key, transport);
      await expectLater(
        engine.upload(huge, language: 'en'),
        throwsA(isA<TranscriptionFailure>().having((e) => e.reason, 'reason', TranscriptionFailureReason.tooLarge)),
      );
      expect(transport.requests, isEmpty);
    }
    expect(
      responseFailure(const RemoteResponse(400, 'maximum audio duration exceeded')),
      TranscriptionFailureReason.tooLarge,
    );
  });

  test('original format first; one conversion only after explicit rejection, cleaned afterward', () async {
    final transport = FakeTranscriptionTransport();
    var conversions = 0;
    var removed = false;
    transport.action = (_) async => transport.requests.length == 1
        ? const RemoteResponse(415, '{}')
        : const RemoteResponse(200, '{"text":"spoken"}');
    final original = AudioUpload(name: 'saved.m4a', path: '/saved.m4a', length: 4, bytes: bytes);
    final engine = RemoteTranscriptionEngine(
      sampleService(consent: true),
      (_) async => key,
      transport,
      convert: (source) async {
        conversions++;
        expect(source, same(original));
        return ConvertedUpload(AudioUpload(name: 'converted.wav', length: bytes.length, bytes: bytes), () async {
          removed = true;
        });
      },
    );
    expect(await engine.upload(original, language: 'ar'), 'spoken');
    expect(transport.requests[0].audio, same(original));
    expect(transport.requests[1].audio!.mime, 'audio/wav');
    expect(conversions, 1);
    expect(removed, isTrue);
  });
}
