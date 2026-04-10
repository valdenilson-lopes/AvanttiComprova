import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Singleton pattern
  static SecureStorageService? _instance;

  factory SecureStorageService() {
    _instance ??= SecureStorageService._internal();
    return _instance!;
  }

  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true, // Mais seguro no Android
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      if (kDebugMode) {
        print('🔒 [SecureStorage] Escrito: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureStorage] Erro ao escrever $key: $e');
      }
      rethrow;
    }
  }

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (kDebugMode && value != null) {
        print('🔒 [SecureStorage] Lido: $key');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureStorage] Erro ao ler $key: $e');
      }
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      if (kDebugMode) {
        print('🔒 [SecureStorage] Deletado: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureStorage] Erro ao deletar $key: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      if (kDebugMode) {
        print('🔒 [SecureStorage] Todos os dados deletados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureStorage] Erro ao deletar todos: $e');
      }
      rethrow;
    }
  }
}
