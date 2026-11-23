import 'credential_reference.dart';
import 'service_config.dart';

class TranscriptionServicesState {
  const TranscriptionServicesState({
    this.services = const [],
    this.selected = 'local',
    this.names = const {},
    this.credentials = const {},
    this.garbage = const [],
    this.legacy = false,
  });
  final List<TranscriptionService> services;
  final String selected;
  final Map<String, CredentialReference> credentials;
  final List<String> garbage;
  final bool legacy;

  /// Keep attribution after a service is deleted. Wipe removes these aliases.
  final Map<String, String> names;
  TranscriptionService? get selectedService => services.where((s) => s.engineId == selected).firstOrNull;

  TranscriptionServicesState copy({
    List<TranscriptionService>? services,
    String? selected,
    Map<String, String>? names,
    Map<String, CredentialReference>? credentials,
    List<String>? garbage,
    bool? legacy,
  }) => TranscriptionServicesState(
    services: services ?? this.services,
    selected: selected ?? this.selected,
    names: names ?? this.names,
    credentials: credentials ?? this.credentials,
    garbage: garbage ?? this.garbage,
    legacy: legacy ?? this.legacy,
  );
}
