import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-owned presentation data, separate from authoritative API records.
abstract interface class LocalUiStore {
  Future<Map<String, Object?>> read(String record);
  Future<void> update(String record, void Function(Map<String, Object?> value) change);
}

abstract class QueuedLocalUiStore implements LocalUiStore {
  Future<void> _tail = Future.value();
  Future<String?> readValue(String key);
  Future<void> writeValue(String key, String value);
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Map<String, Object?> _decode(String? raw) {
    if (raw == null) return {};
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) throw const FormatException('Invalid local presentation record');
    return Map<String, Object?>.from(value);
  }

  @override
  Future<Map<String, Object?>> read(String record) => _serial(() async => _decode(await readValue(record)));
  @override
  Future<void> update(String record, void Function(Map<String, Object?>) change) => _serial(() async {
    final value = _decode(await readValue(record));
    change(value);
    await writeValue(record, jsonEncode(value));
  });
}

class MemoryLocalUiStore extends QueuedLocalUiStore {
  final _values = <String, String>{};
  @override
  Future<String?> readValue(String key) async => _values[key];
  @override
  Future<void> writeValue(String key, String value) async {
    _values[key] = value;
  }
}

class SecureLocalUiStore extends QueuedLocalUiStore {
  SecureLocalUiStore({required this.origin, this.storage = const FlutterSecureStorage()});
  final String origin;
  final FlutterSecureStorage storage;
  String _key(String record) => 'fikrah_ui:$origin:${base64Url.encode(utf8.encode(record))}';
  @override
  Future<String?> readValue(String key) => storage.read(key: _key(key));
  @override
  Future<void> writeValue(String key, String value) => storage.write(key: _key(key), value: value);
}
