import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/transcription/credential_reference.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

class _FaultKeys extends MemoryServiceKeys {
  bool failWrite = false, failDelete = false, unavailable = false;
  Future<void> Function()? afterWrite;
  @override
  Future<void> write(String slot, String key) async {
    await super.write(slot, key); // Also exercises an OS write that partially succeeded.
    if (failWrite) throw StateError('write unavailable');
    await afterWrite?.call();
  }

  @override
  Future<void> delete(String slot) async {
    if (failDelete) throw StateError('delete unavailable');
    await super.delete(slot);
  }

  @override
  Future<String?> read(String slot) async => unavailable ? null : super.read(slot);
}

void main() {
  late FikraDatabase db;
  late _FaultKeys keys;
  late LocalTranscriptionServices repo;
  setUp(() {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    keys = _FaultKeys();
    repo = LocalTranscriptionServices(db, keys);
  });
  Future<Map<String, dynamic>> manifest() async => jsonDecode(
    (await db.select(db.settings).get()).singleWhere((r) => r.key == LocalTranscriptionServices.configKey).value,
  ) as Map<String, dynamic>;

  Future<void> consistent() async {
    final json = await manifest();
    final services = (json['services'] as List).map((v) => TranscriptionService.fromJson(v));
    for (final service in services) {
      final ref = CredentialReference.decode(json['credentials'][service.id])!;
      expect(ref.matches(service), isTrue);
      expect(keys.values[ref.slot], isNotEmpty);
      expect(ref.slot, isNot(service.id));
    }
  }

  for (final failPublish in [false, true]) {
    test('interrupted rotation: write/publish failure leaves old active identity ($failPublish)', () async {
      final service = sampleService(consent: true);
      await repo.save(service, key: 'fake-old');
      await repo.select(service.engineId);
      final oldSlot = (await repo.read()).credentials[service.id]!.slot;
      final changed = sampleService(url: 'https://destination.invalid/v1', consent: true);
      if (failPublish) {
        keys.afterWrite = () => db.customStatement(
          "CREATE TRIGGER fail_publish BEFORE UPDATE ON settings "
          "WHEN NEW.key = 'transcription_services' BEGIN SELECT RAISE(ABORT, 'fixture'); END",
        );
      } else {
        keys.failWrite = true;
      }
      await expectLater(repo.save(changed, key: 'fake-new'), throwsA(anything));
      await consistent();
      // Inspect before recovery: the failed write has an inventoried orphan.
      final json = await manifest();
      expect(json['garbage'], hasLength(1));
      expect(keys.values, hasLength(2));
      if (failPublish) await db.customStatement('DROP TRIGGER fail_publish');
      keys.afterWrite = null;
      keys.failWrite = false;
      final reopened = LocalTranscriptionServices(db, keys);
      expect((await reopened.read()).selected, service.engineId);
      expect((await reopened.read()).credentials[service.id]!.slot, oldSlot);
      expect(await reopened.readKey(service.id, forService: service), 'fake-old');
      expect(keys.values.keys, [oldSlot]);
      await expectLater(reopened.readKey(service.id, forService: changed), throwsA(isA<ServiceConfigException>()));
    });
  }

  test('successful publication precedes cleanup; failed cleanup is retried on reopen', () async {
    final service = sampleService(consent: true);
    await repo.save(service, key: 'fake-old');
    await repo.select(service.engineId);
    final oldSlot = (await repo.read()).credentials[service.id]!.slot;
    keys.failDelete = true;
    await repo.save(service, key: 'fake-new');
    await consistent();
    final current = await repo.read();
    expect(current.selected, service.engineId);
    expect(current.credentials[service.id]!.slot, isNot(oldSlot));
    expect(current.garbage, contains(oldSlot));
    expect(await repo.readKey(service.id, forService: service), 'fake-new');
    keys.failDelete = false;
    final reopened = LocalTranscriptionServices(db, keys);
    expect((await reopened.read()).garbage, isEmpty);
    expect(keys.values, hasLength(1));
  });

  test('missing, unavailable, mismatched and unversioned references fail closed', () async {
    final service = sampleService(consent: true);
    await repo.save(service, key: 'fake-key');
    keys.unavailable = true;
    await expectLater(repo.readKey(service.id), throwsA(isA<ServiceConfigException>()));
    await expectLater(repo.select(service.engineId), throwsA(isA<ServiceConfigException>()));
    keys.unavailable = false;
    final json = await manifest();
    json['credentials'][service.id]['identity'] = 'wrong identity';
    await db
        .into(db.settings)
        .insertOnConflictUpdate(Setting(key: LocalTranscriptionServices.configKey, value: jsonEncode(json)));
    await expectLater(repo.readKey(service.id), throwsA(isA<ServiceConfigException>()));
    expect((await repo.read()).selected, 'local');
    expect(keys.values, isEmpty);
    await repo.save(service, key: 'fake-reentered');
    final missing = await manifest();
    missing['credentials'][service.id].remove('version');
    await db
        .into(db.settings)
        .insertOnConflictUpdate(Setting(key: LocalTranscriptionServices.configKey, value: jsonEncode(missing)));
    await expectLater(repo.readKey(service.id), throwsA(isA<ServiceConfigException>()));
  });

  test('legacy service-id credential is deleted and selection requires key reentry', () async {
    final service = sampleService(consent: true);
    await keys.write(service.id, 'fake-legacy');
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          Setting(
            key: LocalTranscriptionServices.configKey,
            value: jsonEncode({
              'services': [service.toJson()],
            }),
          ),
        );
    await db
        .into(db.settings)
        .insertOnConflictUpdate(Setting(key: LocalTranscriptionServices.engineKey, value: service.engineId));
    expect(await repo.watch().first.then((s) => s.selected), 'local');
    expect(keys.values, isEmpty);
    await expectLater(repo.readKey(service.id), throwsA(isA<ServiceConfigException>()));
    await expectLater(repo.select(service.engineId), throwsA(isA<ServiceConfigException>()));
    await expectLater(repo.save(service), throwsA(isA<ServiceConfigException>()));
    await repo.save(service, key: 'fake-reentered');
    await consistent();
  });

  test('wipe removes staged and unjournaled orphan slots, even without a manifest', () async {
    keys.failWrite = true;
    await expectLater(repo.save(sampleService(), key: 'fake-staged'), throwsStateError);
    keys.values.putIfAbsent('v1-orphan', () => 'fake-orphan');
    await repo.wipe();
    expect(keys.values, isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);
    keys.values['v1-orphan'] = 'fake-orphan';
    await repo.wipe();
    expect(keys.values, isEmpty);
  });
}
