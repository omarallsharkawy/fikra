import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ServiceKeyStore {
  Future<String?> read(String slot);
  Future<void> write(String slot, String key);
  Future<void> delete(String slot);
  Future<void> clear();
}

class SecureServiceKeys implements ServiceKeyStore {
  const SecureServiceKeys([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;
  static const prefix = 'fikra.transcription.api_key.';
  @override
  Future<String?> read(String slot) => storage.read(key: '$prefix$slot');
  @override
  Future<void> write(String slot, String key) => storage.write(key: '$prefix$slot', value: key);
  @override
  Future<void> delete(String slot) => storage.delete(key: '$prefix$slot');
  @override
  Future<void> clear() async {
    for (final key in (await storage.readAll()).keys.where((key) => key.startsWith(prefix))) {
      await storage.delete(key: key);
    }
  }
}
