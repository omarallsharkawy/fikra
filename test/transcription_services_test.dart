import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/service_keys.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

class _NoPurge extends AttachmentStore {
  @override
  Future<void> purgeAll() async {}
}

class _FailDelete extends MemoryServiceKeys {
  bool fail = true;
  @override
  Future<void> delete(String id) async {
    if (fail) throw StateError('keystore unavailable');
    await super.delete(id);
  }
}

void main() {
  late FikraDatabase db;
  late MemoryServiceKeys keys;
  late LocalTranscriptionServices services;
  setUp(() {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    keys = MemoryServiceKeys();
    services = LocalTranscriptionServices(db, keys);
  });

  test('config JSON is non-secret; add/edit/reopen/delete preserves attribution and removes key', () async {
    final s = sampleService();
    await services.save(s, key: 'secret-one');
    final rows = await db.select(db.settings).get();
    final json = rows.singleWhere((r) => r.key == LocalTranscriptionServices.configKey).value;
    expect(json, isNot(contains('secret-one')));
    expect(jsonDecode(json)['services'], hasLength(1));
    expect(keys.values[s.id], 'secret-one');
    final reopened = LocalTranscriptionServices(db, keys);
    expect((await reopened.read()).services.single.model, s.model);
    await expectLater(reopened.select(s.engineId), throwsA(isA<ServiceConfigException>()));
    await reopened.authorize(s);
    await reopened.select(s.engineId);
    final agreed = (await reopened.read()).selectedService!;
    final edit = TranscriptionService(
      id: agreed.id,
      type: agreed.type,
      name: agreed.name,
      baseUrl: agreed.baseUrl,
      model: 'whisper-1',
      language: 'en',
      consentedFor: agreed.consentedFor,
    );
    await reopened.save(edit, key: 'secret-two');
    expect((await reopened.read()).selected, s.engineId);
    expect(await reopened.readKey(s.id), 'secret-two');
    await reopened.save(edit);
    expect(await reopened.readKey(s.id), 'secret-two');
    final renamed = TranscriptionService(
      id: edit.id,
      type: edit.type,
      name: 'Renamed service',
      baseUrl: edit.baseUrl,
      model: edit.model,
      language: edit.language,
      consentedFor: edit.consentedFor,
    );
    await reopened.save(renamed);
    expect((await reopened.read()).selectedService!.consented, isTrue);
    await reopened.delete(s.id);
    final removed = await reopened.read();
    expect(removed.selected, 'local');
    expect(removed.services, isEmpty);
    expect(removed.names[s.id], 'Renamed service');
    expect(keys.values, isEmpty);
    expect(SecureServiceKeys.prefix, 'fikra.transcription.api_key.');
  });

  test('changing destination requires fresh key and consent; stale confirmation cannot authorize it', () async {
    final s = sampleService(consent: true);
    await services.save(s, key: 'old-key');
    await services.select(s.engineId);
    final moved = TranscriptionService(
      id: s.id,
      type: s.type,
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'whisper-large-v3',
      consentedFor: s.consentedFor,
    );
    await expectLater(services.save(moved), throwsA(isA<ServiceConfigException>()));
    await services.save(moved, key: 'new-key');
    expect((await services.read()).selected, 'local');
    expect((await services.read()).services.single.consented, isFalse);
    await expectLater(services.readKey(s.id, forService: s), throwsA(isA<ServiceConfigException>()));
    await services.authorize(s); // Dialog for the old service was still open.
    await expectLater(services.select(s.engineId), throwsA(isA<ServiceConfigException>()));
    await services.authorize(moved);
    await services.select(moved.engineId);
    expect((await services.read()).selectedService!.consented, isTrue);
  });

  test('concurrent adds retain both configs and key failure/delete remains retryable', () async {
    await Future.wait([
      services.save(sampleService(id: 'one'), key: 'a'),
      services.save(sampleService(id: 'two'), key: 'b'),
    ]);
    expect((await services.read()).services.map((s) => s.id), ['one', 'two']);
    final failing = _FailDelete();
    final other = LocalTranscriptionServices(db, failing);
    await expectLater(other.delete('one'), throwsStateError);
    expect((await other.read()).services, hasLength(2));
    failing.fail = false;
    await other.delete('one');
    expect((await other.read()).services.single.id, 'two');
  });

  test('wipe removes configs, aliases, selection and all service keys; theme remains', () async {
    final s = sampleService(consent: true);
    await services.save(s, key: 'secret');
    await services.select(s.engineId);
    final settings = LocalSettingsRepository(db, _NoPurge(), transcriptionServices: services);
    await settings.setTheme(AppTheme.dark);
    await LocalProjectsRepository(db).create('project');
    await settings.wipeAllData();
    expect(keys.values, isEmpty);
    expect((await services.read()).services, isEmpty);
    expect((await services.read()).names, isEmpty);
    expect((await services.read()).selected, 'local');
    expect(await db.select(db.projects).get(), isEmpty);
    expect(await settings.watchTheme().first, AppTheme.dark);
    expect(
      (await db.select(db.settings).get()).map((s) => s.key),
      isNot(contains(LocalTranscriptionServices.configKey)),
    );
  });

  test('HTTPS or literal loopback/private LAN only; no userinfo/query/fragment tricks', () {
    for (final url in [
      'https://api.example.com/v1',
      'http://localhost:8000/v1',
      'http://127.0.0.1:8000',
      'http://10.0.0.3/v1',
      'http://172.16.1.1/v1',
      'http://192.168.1.2/v1',
      'http://[::1]:8000/v1',
      'http://[fd00::1]/v1',
    ]) {
      expect(() => sampleService(url: url).validate(), returnsNormally, reason: url);
    }
    for (final url in [
      'http://api.openai.com/v1',
      'http://8.8.8.8',
      'http://172.32.0.1',
      'http://192.169.1.1',
      'http://private.local',
      'https://key@api.example.com',
      'https://api.example.com?key=secret',
      'https://api.example.com#secret',
      'file:///tmp/key',
      'http://127.0.0.1.evil.example',
    ]) {
      expect(() => sampleService(url: url).validate(), throwsA(isA<ServiceConfigException>()), reason: url);
    }
    expect(
      () => sampleService(type: TranscriptionServiceType.gemini, url: 'https://other.example').validate(),
      throwsA(isA<ServiceConfigException>()),
    );
  });
}
