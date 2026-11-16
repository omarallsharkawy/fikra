import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ServiceKeyStore {
  Future<String?> read(String serviceId);
  Future<void> write(String serviceId, String key);
  Future<void> delete(String serviceId);
  Future<void> clear();
}

class SecureServiceKeys implements ServiceKeyStore {
  const SecureServiceKeys([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;
  static const prefix = 'fikra.transcription.api_key.';
  @override
  Future<String?> read(String serviceId) => storage.read(key: '$prefix$serviceId');
  @override
  Future<void> write(String serviceId, String key) => storage.write(key: '$prefix$serviceId', value: key);
  @override
  Future<void> delete(String serviceId) => storage.delete(key: '$prefix$serviceId');
  @override
  Future<void> clear() async {
    for (final key in (await storage.readAll()).keys.where((key) => key.startsWith(prefix))) {
      await storage.delete(key: key);
    }
  }
}
