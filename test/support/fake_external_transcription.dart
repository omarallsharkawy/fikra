import 'dart:async';

import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/service_keys.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/data/transcription/remote_request.dart';
import 'package:fikra/data/transcription/remote_transport.dart';

class MemoryServiceKeys implements ServiceKeyStore {
  final values = <String, String>{};
  int reads = 0;
  @override
  Future<String?> read(String serviceId) async {
    reads++;
    return values[serviceId];
  }

  @override
  Future<void> write(String serviceId, String key) async {
    values[serviceId] = key;
  }

  @override
  Future<void> delete(String serviceId) async {
    values.remove(serviceId);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

class FakeTranscriptionTransport implements TranscriptionTransport {
  final requests = <RemoteRequest>[];
  final timeouts = <Duration>[];
  Future<RemoteResponse> Function(RemoteRequest)? action;
  RemoteResponse response = const RemoteResponse(200, '{"text":"External transcript"}');
  @override
  Future<RemoteResponse> send(RemoteRequest request, {required Duration timeout}) async {
    requests.add(request);
    timeouts.add(timeout);
    return action == null ? response : action!(request);
  }
}

TranscriptionService sampleService({
  TranscriptionServiceType type = TranscriptionServiceType.openAi,
  String id = 'service-one',
  String? name,
  String? url,
  String? language,
  bool consent = false,
}) {
  final s = TranscriptionService(
    id: id,
    type: type,
    name: name ?? 'My service',
    baseUrl: url ?? defaultServiceUrl(type),
    model: defaultServiceModel(type),
    language: language,
  );
  return consent ? s.authorize() : s;
}

/// Standalone trial widgets have no database. Watch subscriptions belong to the
/// test's zone, and close() is never awaited after their listeners unmount.
class MemoryTranscriptionServices implements TranscriptionServices {
  TranscriptionServicesState state = const TranscriptionServicesState();
  final keys = MemoryServiceKeys();
  final _listeners = <StreamController<TranscriptionServicesState>>{};
  @override
  Future<TranscriptionServicesState> read() async => state;
  @override
  Future<String?> readKey(String id, {TranscriptionService? forService}) async {
    if (forService != null) {
      final current = state.services.where((s) => s.id == id).firstOrNull;
      if (current == null ||
          current.type != forService.type ||
          Uri.parse(current.baseUrl).origin != Uri.parse(forService.baseUrl).origin) {
        throw const ServiceConfigException(ServiceConfigIssue.consentRequired);
      }
    }
    return keys.read(id);
  }

  @override
  Stream<TranscriptionServicesState> watch() {
    late final StreamController<TranscriptionServicesState> out;
    out = StreamController(
      onListen: () => out.add(state),
      onCancel: () async {
        _listeners.remove(out);
      },
    );
    _listeners.add(out);
    return out.stream;
  }

  void _emit() {
    for (final out in List.of(_listeners)) {
      out.add(state);
    }
  }

  @override
  Future<void> save(TranscriptionService s, {String? key}) async {
    s.validate();
    state = TranscriptionServicesState(
      services: [...state.services.where((v) => v.id != s.id), s],
      selected: state.selected,
      names: {...state.names, s.id: s.name},
    );
    if (key != null) await keys.write(s.id, key);
    _emit();
  }

  @override
  Future<void> select(String engineId) async {
    if (engineId != 'local' && !state.services.any((s) => s.engineId == engineId && s.consented)) {
      throw const ServiceConfigException(ServiceConfigIssue.consentRequired);
    }
    state = TranscriptionServicesState(services: state.services, selected: engineId, names: state.names);
    _emit();
  }

  @override
  Future<void> authorize(TranscriptionService s) async {
    state = TranscriptionServicesState(
      services: [
        for (final v in state.services) v.id == s.id && v.consentIdentity == s.consentIdentity ? v.authorize() : v,
      ],
      selected: state.selected,
      names: state.names,
    );
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    await keys.delete(id);
    state = TranscriptionServicesState(
      services: state.services.where((s) => s.id != id).toList(),
      selected: state.selected == 'remote:$id' ? 'local' : state.selected,
      names: state.names,
    );
    _emit();
  }

  @override
  Future<void> wipe() async {
    await keys.clear();
    state = const TranscriptionServicesState();
    _emit();
  }

  void dispose() {
    for (final out in List.of(_listeners)) {
      unawaited(out.close());
    }
    _listeners.clear();
  }
}
