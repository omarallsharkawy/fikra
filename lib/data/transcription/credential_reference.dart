import 'dart:convert';

import 'service_config.dart';

/// Non-secret pointer. The slot is never reused, even for the same service.
class CredentialReference {
  const CredentialReference(this.slot, this.identity);
  final String slot, identity;
  static String identityOf(TranscriptionService service) {
    service.validate();
    return jsonEncode([service.type.name, Uri.parse(service.baseUrl).origin]);
  }

  bool matches(TranscriptionService service) {
    try {
      return identity == identityOf(service);
    } on ServiceConfigException {
      return false;
    }
  }

  Map<String, Object> toJson() => {'version': 1, 'slot': slot, 'identity': identity};
  static CredentialReference? decode(dynamic value) {
    if (value is! Map || value['version'] != 1 || value['slot'] is! String || value['identity'] is! String) {
      return null;
    }
    final slot = value['slot'] as String;
    if (!RegExp(r'^v1-[a-zA-Z0-9-]+$').hasMatch(slot)) return null;
    return CredentialReference(slot, value['identity'] as String);
  }
}
