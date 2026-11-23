import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';
import 'repositories.dart';

/// One protected record keeps the replacement pair together. Not used to
/// manufacture credentials for development sessions.
class SecureSessionVault implements SessionVault {
  const SecureSessionVault({this.storage = const FlutterSecureStorage()});
  final FlutterSecureStorage storage;
  static const _key = 'fikrah_product_session';
  @override
  Future<TokenPair?> read() async {
    final raw = await storage.read(key: _key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return TokenPair(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  @override
  Future<void> replace(TokenPair tokens) => storage.write(
    key: _key,
    value: jsonEncode({
      'access': tokens.access,
      'refresh': tokens.refresh,
      'expires_at': tokens.expiresAt.toUtc().toIso8601String(),
    }),
  );
  @override
  Future<void> clear() => storage.delete(key: _key);
}
