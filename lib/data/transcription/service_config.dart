import 'dart:convert';
import 'dart:io';

enum TranscriptionServiceType { openAi, gemini, elevenLabs, qwen }

enum ServiceConfigIssue { invalidUrl, invalidFields, keyRequired, consentRequired }

class ServiceConfigException implements Exception {
  const ServiceConfigException(this.issue);
  final ServiceConfigIssue issue;
}

class TranscriptionService {
  const TranscriptionService({
    required this.id,
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.language,
    this.consentedFor,
  });
  final String id, name, baseUrl, model;
  final TranscriptionServiceType type;
  final String? language, consentedFor;
  String get engineId => 'remote:$id';
  String get consentIdentity => jsonEncode([type.name, baseUrl]);
  bool get consented => consentedFor == consentIdentity;
  bool get insecure => Uri.parse(baseUrl).scheme == 'http';
  TranscriptionService authorize() => TranscriptionService(
    id: id,
    type: type,
    name: name,
    baseUrl: baseUrl,
    model: model,
    language: language,
    consentedFor: consentIdentity,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'baseUrl': baseUrl,
    'model': model,
    'language': language,
    'consentedFor': consentedFor,
  };
  factory TranscriptionService.fromJson(Map<String, dynamic> value) => TranscriptionService(
    id: value['id'] as String,
    type: TranscriptionServiceType.values.byName(value['type'] as String),
    name: value['name'] as String,
    baseUrl: value['baseUrl'] as String,
    model: value['model'] as String,
    language: value['language'] as String?,
    consentedFor: value['consentedFor'] as String?,
  );

  void validate() {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 80 ||
        !RegExp(r'^[a-zA-Z0-9._:/-]{1,160}$').hasMatch(model) ||
        (language != null && !RegExp(r'^[a-zA-Z-]{2,30}$').hasMatch(language!))) {
      throw const ServiceConfigException(ServiceConfigIssue.invalidFields);
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !validServiceUrl(uri)) throw const ServiceConfigException(ServiceConfigIssue.invalidUrl);
    // Keys for the fixed-provider forms can only reach their actual API host.
    if ((type == TranscriptionServiceType.gemini && baseUrl != defaultServiceUrl(type)) ||
        (type == TranscriptionServiceType.elevenLabs && baseUrl != defaultServiceUrl(type))) {
      throw const ServiceConfigException(ServiceConfigIssue.invalidUrl);
    }
  }
}

String defaultServiceUrl(TranscriptionServiceType type) => switch (type) {
  TranscriptionServiceType.openAi => 'https://api.openai.com/v1',
  TranscriptionServiceType.gemini => 'https://generativelanguage.googleapis.com/v1beta',
  TranscriptionServiceType.elevenLabs => 'https://api.elevenlabs.io/v1',
  TranscriptionServiceType.qwen => qwenInternationalUrl,
};
const qwenInternationalUrl = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';
const qwenMainlandUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
String defaultServiceModel(TranscriptionServiceType type) => switch (type) {
  TranscriptionServiceType.openAi => 'gpt-transcribe',
  TranscriptionServiceType.gemini => 'gemini-3.5-flash-lite',
  TranscriptionServiceType.elevenLabs => 'scribe_v3',
  TranscriptionServiceType.qwen => 'qwen3-asr-flash',
};

bool validServiceUrl(Uri uri) =>
    uri.hasAuthority &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasQuery &&
    !uri.hasFragment &&
    (uri.scheme == 'https' || (uri.scheme == 'http' && privateServiceHost(uri.host)));

/// Literal addresses only: no DNS lookup or credentials sent to an arbitrary
/// hostname merely because it ends in .local. Bracketed IPv6 is normalized.
bool privateServiceHost(String host) {
  if (host.toLowerCase() == 'localhost') return true;
  final address = InternetAddress.tryParse(host);
  if (address == null) return false;
  if (address.isLoopback) return true;
  final b = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168);
  }
  return b[0] & 0xfe == 0xfc; // IPv6 unique-local fc00::/7.
}

String? serviceOrigin(String value) {
  try {
    return Uri.tryParse(value.trim())?.origin;
  } catch (_) {
    return null;
  } // Partial URL while the user edits a field.
}
