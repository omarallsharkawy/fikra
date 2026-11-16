import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/transcription/model_catalog.dart';
import 'package:fikra/data/transcription/model_discovery.dart';
import 'package:fikra/data/transcription/remote_builders.dart';
import 'package:fikra/data/transcription/remote_request.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

void main() {
  late FikraDatabase db;
  late FakeTranscriptionTransport http;
  late ModelDiscovery discovery;
  setUp(() {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    http = FakeTranscriptionTransport();
    discovery = ModelDiscovery(db, http);
  });
  test('every offered batch model is supported, defaults are catalog recommendations', () async {
    for (final m in transcriptionCatalog) {
      final service = TranscriptionService(
        id: 'catalog',
        type: m.type,
        name: 'catalog',
        baseUrl: m.groqOnly ? 'https://api.groq.com/openai/v1' : defaultServiceUrl(m.type),
        batchModel: m.id,
      );
      final future = buildTranscriptionRequest(
        service,
        'fake',
        AudioUpload(name: 'a.wav', length: 1, bytes: Uint8List(1)),
        'ar',
      );
      if (m.supported) {
        final request = await future;
        expect(request.method, 'POST');
        if (m.id == 'gpt-4o-transcribe-diarize') expect(request.fields['chunking_strategy'], 'auto');
      } else {
        await expectLater(future, throwsA(isA<TranscriptionFailure>()));
      }
    }
    for (final type in TranscriptionServiceType.values) {
      expect(defaultServiceModel(type), catalogDefault(type));
      expect(transcriptionCatalogMatch(type, defaultServiceModel(type))!.status, ModelStatus.recommended);
      expect(catalogLiveDefault(type), isNull);
    }
    expect(catalogFor(TranscriptionServiceType.openAi, 'https://api.groq.com/openai/v1').map((m) => m.id), [
      'whisper-large-v3-turbo',
      'whisper-large-v3',
    ]);
    expect(
      catalogFor(TranscriptionServiceType.openAi, 'https://api.groq.com.evil.example/v1').any((m) => m.groqOnly),
      isFalse,
    );
    expect(
      transcriptionCatalog
          .where((m) => m.type == TranscriptionServiceType.openAi && m.status == ModelStatus.legacy)
          .every((m) => m.shutdown == '2027-02-26'),
      isTrue,
    );
  });
  test('old model JSON reads forever; new batch/live shape roundtrips without changing consent', () {
    final old = sampleService(consent: true).toJson()
      ..remove('batchModel')
      ..remove('liveModel');
    old['model'] = 'whisper-1';
    final read = TranscriptionService.fromJson(Map<String, dynamic>.from(old));
    expect(read.batchModel, 'whisper-1');
    expect(read.consented, isTrue);
    final next = TranscriptionService(
      id: read.id,
      type: read.type,
      name: read.name,
      baseUrl: read.baseUrl,
      batchModel: read.batchModel,
      liveModel: 'future-live',
      consentedFor: read.consentedFor,
    );
    expect(next.toJson().containsKey('model'), isFalse);
    final restored = TranscriptionService.fromJson(Map<String, dynamic>.from(next.toJson()));
    expect(restored.batchModel, read.batchModel);
    expect(restored.liveModel, 'future-live');
    expect(restored.consented, isTrue);
  });
  test('GET request URLs/auth and Gemini pagination have no audio/body', () async {
    for (final type in [
      TranscriptionServiceType.openAi,
      TranscriptionServiceType.gemini,
      TranscriptionServiceType.elevenLabs,
    ]) {
      final request = discoveryRequest(sampleService(type: type), 'secret', pageToken: 'next /+');
      expect(request.method, 'GET');
      expect(request.audio, isNull);
      expect(request.contentLength, 0);
      expect(await request.body().toList(), isEmpty);
      expect(request.uri.path, '${Uri.parse(defaultServiceUrl(type)).path}/models');
      expect(request.headers, switch (type) {
        TranscriptionServiceType.gemini => {'x-goog-api-key': 'secret'},
        TranscriptionServiceType.elevenLabs => {'xi-api-key': 'secret'},
        _ => {'Authorization': 'Bearer secret'},
      });
      if (type == TranscriptionServiceType.gemini) {
        expect(request.uri.queryParameters['pageToken'], 'next /+');
      } else {
        expect(request.uri.hasQuery, isFalse);
      }
    }
  });
  test('parsers read provider IDs without inferring capability', () {
    expect(parseDiscovery(TranscriptionServiceType.openAi, '{"data":[{"id":"whisper-1"}]}').$1, {'whisper-1'});
    expect(parseDiscovery(TranscriptionServiceType.elevenLabs, '[{"model_id":"scribe_v3"}]').$1, {'scribe_v3'});
    final page = parseDiscovery(
      TranscriptionServiceType.gemini,
      '{"models":[{"name":"models/gemini-3.8-flash"}],"nextPageToken":"next"}',
    );
    expect(page.$1, {'gemini-3.8-flash'});
    expect(page.$2, 'next');
  });
  test('paginated refresh marks only known IDs and caches per service/destination', () async {
    final s = sampleService(type: TranscriptionServiceType.gemini, consent: true);
    http.action = (r) async => RemoteResponse(
      200,
      jsonEncode({
        'models': [
          {'name': http.requests.length == 1 ? 'models/gemini-3.5-flash-lite' : 'models/unknown-audio'},
        ],
        if (http.requests.length == 1) 'nextPageToken': 'next',
      }),
    );
    final found = await discovery.refresh(s, () async => 'secret');
    expect(found.ids, {'gemini-3.5-flash-lite'});
    expect(http.requests, hasLength(2));
    expect(http.requests[1].uri.queryParameters['pageToken'], 'next');
    expect((await discovery.cached(s))!.ids, found.ids);
    expect(await discovery.cached(sampleService(id: 'other', type: s.type, consent: true)), isNull);
  });
  test('failure retains cache/selection; no consent means no key read or request', () async {
    final s = sampleService(consent: true);
    final repo = LocalTranscriptionServices(db, MemoryServiceKeys());
    await repo.save(s, key: 'secret');
    await repo.select(s.engineId);
    http.response = const RemoteResponse(200, '{"data":[{"id":"gpt-transcribe"},{"id":"unknown"}]}');
    await discovery.refresh(s, () async => 'secret');
    final before = (await discovery.cached(s))!;
    for (final error in [
      const RemoteResponse(401, 'secret'),
      const RemoteResponse(429, 'secret'),
      const RemoteResponse(500, 'secret'),
      const RemoteResponse(200, 'secret'),
      TimeoutException('secret'),
      const SocketException('secret'),
    ]) {
      http.action = (_) async {
        if (error is RemoteResponse) return error;
        throw error;
      };
      await expectLater(
        discovery.refresh(s, () async => 'secret'),
        throwsA(isA<TranscriptionFailure>().having((e) => e.toString().contains('secret'), 'redacted', isFalse)),
      );
      expect((await discovery.cached(s))!.checkedAt, before.checkedAt);
      expect((await repo.read()).selectedService!.batchModel, s.batchModel);
    }
    http.requests.clear();
    var reads = 0;
    await expectLater(
      discovery.refresh(sampleService(), () async {
        reads++;
        return 'secret';
      }),
      throwsA(isA<TranscriptionFailure>()),
    );
    expect(reads, 0);
    expect(http.requests, isEmpty);
    await repo.delete(s.id);
    expect(await discovery.cached(s), isNull);
  });
  test('Qwen discovery is intentionally skipped before reading a key or making a request', () async {
    var reads = 0;
    await expectLater(
      discovery.refresh(sampleService(type: TranscriptionServiceType.qwen, consent: true), () async {
        reads++;
        return 'secret';
      }),
      throwsA(isA<TranscriptionFailure>()),
    );
    expect(reads, 0);
    expect(http.requests, isEmpty);
  });
}
