import 'dart:convert';

import 'package:drift/drift.dart';

import '../ids.dart';
import '../local/database.dart';
import 'credential_reference.dart';
import 'model_discovery.dart';
import 'service_config.dart';
import 'service_keys.dart';
import 'services_state.dart';

export 'services_state.dart';

abstract interface class TranscriptionServices {
  Future<TranscriptionServicesState> read();
  Stream<TranscriptionServicesState> watch();
  Future<String?> readKey(String id, {TranscriptionService? forService});
  Future<void> save(TranscriptionService service, {String? key});
  Future<void> select(String engineId);
  Future<void> authorize(TranscriptionService service);
  Future<void> delete(String id);
  Future<void> wipe();
}

class LocalTranscriptionServices implements TranscriptionServices {
  LocalTranscriptionServices(this.db, this.keys);
  final FikraDatabase db;
  final ServiceKeyStore keys;
  static const configKey = 'transcription_services';
  static const engineKey = 'transcription_engine';
  Future<void> _tail = Future.value();

  Future<T> _change<T>(Future<T> Function() operation) {
    final job = _tail.then((_) => operation());
    _tail = job.then<void>((_) {}, onError: (Object _) {});
    return job;
  }

  TranscriptionServicesState _decode(List<Setting> rows) {
    final values = {for (final row in rows) row.key: row.value};
    final json = values[configKey] == null
        ? <String, dynamic>{}
        : jsonDecode(values[configKey]!) as Map<String, dynamic>;
    return TranscriptionServicesState(
      services: [
        for (final item in json['services'] as List<dynamic>? ?? [])
          TranscriptionService.fromJson(item as Map<String, dynamic>),
      ],
      names: Map<String, String>.from(json['names'] as Map? ?? {}),
      credentials: _decodeCredentials(json['credentials']),
      garbage: List<String>.from(json['garbage'] as List? ?? []),
      legacy: json['credentialVersion'] != 1,
      selected: values[engineKey] ?? 'local',
    );
  }

  Future<TranscriptionServicesState> _read() async =>
      _decode(await (db.select(db.settings)..where((s) => s.key.isIn([configKey, engineKey]))).get());

  // Old service-id slots have no provable destination. Never adopt them.
  Future<TranscriptionServicesState> _load() async {
    var state = await _read();
    final invalid = state.services.where((s) => state.credentials[s.id]?.matches(s) != true).toList();
    if (invalid.isNotEmpty) {
      final ids = invalid.map((s) => s.id).toSet();
      final selected = invalid.any((s) => s.engineId == state.selected) ? 'local' : state.selected;
      final garbage = {
        ...state.garbage,
        if (state.legacy) ...ids,
        for (final id in ids)
          if (state.credentials[id] case final ref?) ref.slot,
      };
      final refs = {...state.credentials}..removeWhere((id, _) => ids.contains(id));
      final next = state.copy(selected: selected, credentials: refs, garbage: garbage.toList(), legacy: false);
      if (state.legacy ||
          selected != state.selected ||
          refs.length != state.credentials.length ||
          garbage.length != state.garbage.length) {
        await _write(next);
      }
      state = next;
    }
    if (state.selected != 'local' && state.selectedService == null) {
      final id = state.selected.startsWith('remote:') ? state.selected.substring(7) : null;
      state = state.copy(
        selected: 'local',
        legacy: false,
        garbage: {...state.garbage, if (state.legacy && id != null) id}.toList(),
      );
      await _write(state);
    }
    return _cleanup(state);
  }

  Future<TranscriptionServicesState> _cleanup(TranscriptionServicesState state) async {
    final remaining = <String>[];
    for (final slot in state.garbage) {
      try {
        await keys.delete(slot);
      } catch (_) {
        remaining.add(slot);
      }
    }
    if (remaining.length != state.garbage.length) {
      final next = state.copy(garbage: remaining);
      try {
        await _write(next);
        return next;
      } catch (_) {
        // Keep the journal for the next retry. Deleting twice is harmless.
      }
    }
    return state;
  }

  @override
  Future<TranscriptionServicesState> read() => _change(_load);

  @override
  Stream<TranscriptionServicesState> watch() async* {
    await read();
    yield* (db.select(db.settings)..where((s) => s.key.isIn([configKey, engineKey]))).watch().map((rows) {
      final state = _decode(rows);
      final service = state.selectedService;
      return state.selected != 'local' && (service == null || state.credentials[service.id]?.matches(service) != true)
          ? state.copy(selected: 'local')
          : state;
    });
  }

  @override
  Future<String?> readKey(String id, {TranscriptionService? forService}) => _change(() async {
    final state = await _load();
    final current = state.services.where((s) => s.id == id).firstOrNull;
    final ref = state.credentials[id];
    if (current == null ||
        ref == null ||
        !ref.matches(current) ||
        (forService != null && (forService.id != id || !ref.matches(forService)))) {
      throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
    }
    final key = await keys.read(ref.slot);
    if (key == null || key.trim().isEmpty) throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
    return key;
  });

  Future<void> _write(TranscriptionServicesState state) => db.transaction(() async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          Setting(
            key: configKey,
            value: jsonEncode({
              'services': state.services.map((s) => s.toJson()).toList(),
              'names': state.names,
              'credentialVersion': 1,
              'credentials': state.credentials.map((id, ref) => MapEntry(id, ref.toJson())),
              'garbage': state.garbage,
            }),
          ),
        );
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: engineKey, value: state.selected));
  });

  @override
  Future<void> save(TranscriptionService service, {String? key}) => _change(() async {
    service.validate();
    var state = await _load();
    final previous = state.credentials[service.id];
    final CredentialReference ref;
    final freshKey = key?.trim();
    if (freshKey != null && freshKey.isNotEmpty) {
      ref = CredentialReference('v1-${newId()}', CredentialReference.identityOf(service));
      // Journal the slot before the OS write, without changing active config.
      state = state.copy(garbage: [...state.garbage, ref.slot]);
      await _write(state);
      await keys.write(ref.slot, freshKey);
    } else {
      if (previous == null || !previous.matches(service) || (await keys.read(previous.slot))?.isNotEmpty != true) {
        throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
      }
      ref = previous;
    }
    final next = state.copy(
      services: state.services.any((s) => s.id == service.id)
          ? [for (final s in state.services) s.id == service.id ? service : s]
          : [...state.services, service],
      selected: state.selected == service.engineId && !service.consented ? 'local' : state.selected,
      names: {...state.names, service.id: service.name},
      credentials: {...state.credentials, service.id: ref},
      garbage: {
        ...state.garbage.where((slot) => slot != ref.slot),
        if (previous != null && previous.slot != ref.slot) previous.slot,
      }.toList(),
    );
    // Config, reference and selection become visible together, after the key.
    await _write(next);
    await _cleanup(next);
  });

  @override
  Future<void> select(String engineId) => _change(() async {
    final state = await _load();
    if (engineId != 'local') {
      final service = state.services.where((s) => s.engineId == engineId).firstOrNull;
      if (service == null || !service.consented) {
        throw const ServiceConfigException(ServiceConfigIssue.consentRequired);
      }
      final ref = state.credentials[service.id];
      if (ref == null || !ref.matches(service) || (await keys.read(ref.slot))?.isNotEmpty != true) {
        throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
      }
    }
    await _write(state.copy(selected: engineId));
  });

  @override
  Future<void> authorize(TranscriptionService service) => _change(() async {
    final state = await _load();
    await _write(
      state.copy(
        services: [
          for (final s in state.services)
            s.id == service.id && s.consentIdentity == service.consentIdentity ? s.authorize() : s,
        ],
      ),
    );
  });

  @override
  Future<void> delete(String id) => _change(() async {
    final state = await _load();
    final cacheKeys = (await db.select(db.settings).get())
        .where((r) => r.key.startsWith('${ModelDiscovery.prefix}$id.'))
        .map((r) => r.key);
    final refs = {...state.credentials}..remove(id);
    final next = state.copy(
      services: state.services.where((s) => s.id != id).toList(),
      credentials: refs,
      selected: state.selected == 'remote:$id' ? 'local' : state.selected,
      garbage: {...state.garbage, id, if (state.credentials[id] case final ref?) ref.slot}.toList(),
    );
    await db.transaction(() async {
      await (db.delete(db.settings)..where((r) => r.key.isIn(cacheKeys))).go();
      await _write(next);
    });
    await _cleanup(next);
  });

  @override
  Future<void> wipe() => _change(() async {
    // Includes staged/orphan slots even when a manifest publish never happened.
    await keys.clear();
    await (db.delete(
      db.settings,
    )..where((s) => s.key.isIn([configKey, engineKey]) | s.key.like('${ModelDiscovery.prefix}%'))).go();
  });
}

/// Decodes stored credential references, dropping entries that do not decode.
Map<String, CredentialReference> _decodeCredentials(Object? raw) {
  final out = <String, CredentialReference>{};
  for (final entry in (raw as Map? ?? const {}).entries) {
    final ref = CredentialReference.decode(entry.value);
    if (ref != null) out[entry.key as String] = ref;
  }
  return out;
}
