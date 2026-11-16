import 'dart:convert';

import '../local/database.dart';
import 'service_config.dart';
import 'service_keys.dart';

class TranscriptionServicesState {
  const TranscriptionServicesState({this.services = const [], this.selected = 'local', this.names = const {}});
  final List<TranscriptionService> services;
  final String selected;

  /// Keep attribution after a service is deleted. Wipe removes these aliases.
  final Map<String, String> names;
  TranscriptionService? get selectedService => services.where((s) => s.engineId == selected).firstOrNull;
}

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
      selected: values[engineKey] ?? 'local',
    );
  }

  Future<TranscriptionServicesState> _read() async =>
      _decode(await (db.select(db.settings)..where((s) => s.key.isIn([configKey, engineKey]))).get());
  @override
  Future<TranscriptionServicesState> read() async {
    await _tail;
    return _read();
  }

  @override
  Stream<TranscriptionServicesState> watch() =>
      (db.select(db.settings)..where((s) => s.key.isIn([configKey, engineKey]))).watch().map(_decode);
  @override
  Future<String?> readKey(String id, {TranscriptionService? forService}) => _change(() async {
    if (forService != null) {
      final current = (await _read()).services.where((s) => s.id == id).firstOrNull;
      if (current == null ||
          current.type != forService.type ||
          Uri.parse(current.baseUrl).origin != Uri.parse(forService.baseUrl).origin) {
        throw const ServiceConfigException(ServiceConfigIssue.consentRequired);
      }
    }
    return keys.read(id);
  });

  Future<void> _write(TranscriptionServicesState state) => db.transaction(() async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          Setting(
            key: configKey,
            value: jsonEncode({'services': state.services.map((s) => s.toJson()).toList(), 'names': state.names}),
          ),
        );
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: engineKey, value: state.selected));
  });

  @override
  Future<void> save(TranscriptionService service, {String? key}) => _change(() async {
    service.validate();
    final state = await _read();
    final old = state.services.where((s) => s.id == service.id).firstOrNull;
    final needsKey =
        old == null || old.type != service.type || Uri.parse(old.baseUrl).origin != Uri.parse(service.baseUrl).origin;
    if (needsKey && (key == null || key.trim().isEmpty)) {
      throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
    }
    // Publish the manifest before touching secure storage so every secret is
    // discoverable for delete/wipe, even if an OS key operation is interrupted.
    // An edited active service is deselected until the save/key write finishes.
    await _write(
      TranscriptionServicesState(
        services: old == null
            ? [...state.services, service]
            : [for (final s in state.services) s.id == service.id ? service : s],
        selected: state.selected == service.engineId ? 'local' : state.selected,
        names: {...state.names, service.id: service.name},
      ),
    );
    if (key != null && key.trim().isNotEmpty) await keys.write(service.id, key.trim());
    if (state.selected == service.engineId && service.consented) {
      await _write(
        TranscriptionServicesState(
          services: old == null
              ? [...state.services, service]
              : [for (final s in state.services) s.id == service.id ? service : s],
          selected: service.engineId,
          names: {...state.names, service.id: service.name},
        ),
      );
    }
  });

  @override
  Future<void> select(String engineId) => _change(() async {
    final state = await _read();
    if (engineId != 'local') {
      final service = state.services.where((s) => s.engineId == engineId).firstOrNull;
      if (service == null || !service.consented) {
        throw const ServiceConfigException(ServiceConfigIssue.consentRequired);
      }
    }
    await _write(TranscriptionServicesState(services: state.services, selected: engineId, names: state.names));
  });

  @override
  Future<void> authorize(TranscriptionService service) => _change(() async {
    final state = await _read();
    // Do not authorize a stale destination that changed while a dialog was up.
    await _write(
      TranscriptionServicesState(
        services: [
          for (final s in state.services)
            s.id == service.id && s.consentIdentity == service.consentIdentity ? s.authorize() : s,
        ],
        selected: state.selected,
        names: state.names,
      ),
    );
  });

  @override
  Future<void> delete(String id) => _change(() async {
    final state = await _read();
    await keys.delete(id); // On failure retain the manifest for a safe retry.
    await _write(
      TranscriptionServicesState(
        services: state.services.where((s) => s.id != id).toList(),
        selected: state.selected == 'remote:$id' ? 'local' : state.selected,
        names: state.names,
      ),
    );
  });

  @override
  Future<void> wipe() => _change(() async {
    final manifest = await (db.select(db.settings)..where((s) => s.key.equals(configKey))).getSingleOrNull();
    if (manifest != null) await keys.clear();
    await (db.delete(db.settings)..where((s) => s.key.isIn([configKey, engineKey]))).go();
  });
}
