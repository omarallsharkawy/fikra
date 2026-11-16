import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../local/database.dart';
import '../processing/transcription_engine.dart';
import 'model_catalog.dart';
import 'remote_builders.dart';
import 'remote_request.dart';
import 'remote_transport.dart';
import 'service_config.dart';

class DiscoveredModels {
  const DiscoveredModels(this.ids, this.checkedAt);
  final Set<String> ids;
  final DateTime checkedAt;
}

class ModelDiscovery {
  ModelDiscovery(this.db, this.transport);
  final FikraDatabase db;
  final TranscriptionTransport transport;
  static const prefix = 'transcription_models.';
  String _key(TranscriptionService s) => '$prefix${s.id}.${Uri.encodeComponent(s.baseUrl)}';

  Future<DiscoveredModels?> cached(TranscriptionService service) async {
    final row = await (db.select(db.settings)..where((r) => r.key.equals(_key(service)))).getSingleOrNull();
    if (row == null) return null;
    try {
      final json = jsonDecode(row.value) as Map;
      if (json['type'] != service.type.name) return null;
      return DiscoveredModels(Set<String>.from(json['ids'] as List), DateTime.parse(json['checkedAt'] as String));
    } catch (_) {
      return null;
    } // A malformed cache never changes the selected model.
  }

  Future<DiscoveredModels> refresh(TranscriptionService service, Future<String?> Function() readKey) async {
    if (!service.consented) throw const TranscriptionFailure(TranscriptionFailureReason.consentRequired);
    service.validate();
    // Native DashScope discovery needs workspace-specific context. Do not guess.
    if (service.type == TranscriptionServiceType.qwen) {
      throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    }
    try {
      final key = await readKey();
      if (key == null || key.trim().isEmpty || RegExp(r'[\r\n]').hasMatch(key)) {
        throw const TranscriptionFailure(TranscriptionFailureReason.keyRejected);
      }
      final ids = <String>{}, tokens = <String>{};
      final watch = Stopwatch()..start();
      String? token;
      var received = 0;
      for (var page = 0; page < 50; page++) {
        final remaining = const Duration(seconds: 60) - watch.elapsed;
        if (remaining <= Duration.zero) throw const TranscriptionFailure(TranscriptionFailureReason.remoteTimeout);
        final request = discoveryRequest(service, key, pageToken: token);
        final response = await transport.send(request, timeout: remaining);
        if (response.status < 200 || response.status >= 300) throw TranscriptionFailure(responseFailure(response));
        received += utf8.encode(response.body).length;
        if (received > 1024 * 1024) throw const FormatException();
        final result = parseDiscovery(service.type, response.body);
        ids.addAll(result.$1);
        token = result.$2;
        if (token == null || token.isEmpty) {
          final allowed = catalogFor(service.type, service.baseUrl).map((m) => m.id).toSet();
          final found = DiscoveredModels(ids.intersection(allowed), DateTime.now().toUtc());
          await db
              .into(db.settings)
              .insertOnConflictUpdate(
                Setting(
                  key: _key(service),
                  value: jsonEncode({
                    'type': service.type.name,
                    'ids': found.ids.toList(),
                    'checkedAt': found.checkedAt.toIso8601String(),
                  }),
                ),
              );
          return found;
        }
        if (!tokens.add(token)) throw const FormatException();
      }
      throw const FormatException();
    } on TranscriptionFailure {
      rethrow;
    } on TimeoutException {
      throw const TranscriptionFailure(TranscriptionFailureReason.remoteTimeout);
    } on SocketException {
      throw const TranscriptionFailure(TranscriptionFailureReason.offline);
    } catch (_) {
      throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
    }
  }
}

RemoteRequest discoveryRequest(TranscriptionService service, String key, {String? pageToken}) {
  // https://developers.openai.com/api/reference/resources/models/methods/list
  // https://aistudio.google.com/api-reference/models (pageToken/nextPageToken)
  // https://elevenlabs.io/docs/api-reference/models/list
  service.validate();
  var uri = serviceEndpoint(service, 'models');
  final headers = switch (service.type) {
    TranscriptionServiceType.gemini => {'x-goog-api-key': key},
    TranscriptionServiceType.elevenLabs => {'xi-api-key': key},
    _ => {'Authorization': 'Bearer $key'},
  };
  if (service.type == TranscriptionServiceType.gemini) {
    uri = uri.replace(queryParameters: {'pageSize': '100', 'pageToken': ?pageToken});
  }
  return RemoteRequest.get(uri, headers);
}

(Set<String>, String?) parseDiscovery(TranscriptionServiceType type, String body) {
  try {
    final dynamic json = jsonDecode(body);
    final List<dynamic> rows = switch (type) {
      TranscriptionServiceType.openAi => (json as Map)['data'] as List,
      TranscriptionServiceType.gemini => (json as Map)['models'] as List? ?? const [],
      TranscriptionServiceType.elevenLabs => json as List,
      TranscriptionServiceType.qwen => throw const FormatException(),
    };
    final field = switch (type) {
      TranscriptionServiceType.gemini => 'name',
      TranscriptionServiceType.elevenLabs => 'model_id',
      _ => 'id',
    };
    return (
      {for (final row in rows) (row[field] as String).replaceFirst(RegExp(r'^models/'), '')},
      type == TranscriptionServiceType.gemini ? json['nextPageToken'] as String? : null,
    );
  } catch (_) {
    throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
  }
}
