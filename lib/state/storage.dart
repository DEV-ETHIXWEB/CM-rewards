import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the app keeps member data between launches.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Encrypted at rest: the iOS Keychain, and AES-GCM with a key held in the
/// Android Keystore. Data stays on this device and is not included in backups
/// that leave it.
class SecureStore implements KeyValueStore {
  const SecureStore();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    aOptions: AndroidOptions(),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Keeps data in memory only. Used by tests and as a fallback.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? values]) : values = {...?values};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
