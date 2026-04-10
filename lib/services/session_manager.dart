import 'package:app/services/secure_storage_service.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'dart:convert';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _deviceIdKey = 'device_id';
  static const String _userKey = 'user_data';

  final SecureStorageService _secureStorage;
  final IStorageService _storage;

  SessionManager({
    required SecureStorageService secureStorage,
    required IStorageService storage,
  })  : _secureStorage = secureStorage,
        _storage = storage;

  /// Salva sessão completa (token no SecureStorage, user no SharedPreferences)
  Future<void> saveSession(UserModel user) async {
    if (user.token != null && user.token!.isNotEmpty) {
      await _secureStorage.write(_tokenKey, user.token!);
    }

    if (user.deviceId != null && user.deviceId!.isNotEmpty) {
      await _secureStorage.write(_deviceIdKey, user.deviceId!);
    }

    // Salva user sem token como JSON string
    final userWithoutToken = user.copyWith(token: null);
    final jsonString = jsonEncode(userWithoutToken.toJson());
    await _storage.setString(_userKey, jsonString);
  }

  /// Recupera o token
  Future<String?> getToken() async {
    return await _secureStorage.read(_tokenKey);
  }

  /// Recupera o deviceId
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(_deviceIdKey);
  }

  /// Recupera sessão completa (token + deviceId)
  Future<Map<String, String>?> getFullSession() async {
    final token = await getToken();
    final deviceId = await getDeviceId();

    if (token == null && deviceId == null) return null;

    return {
      if (token != null) 'token': token,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  /// Recupera o usuário salvo
  Future<UserModel?> getUser() async {
    final jsonString = _storage.getString(_userKey);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UserModel.fromJson(json);
    } catch (e) {
      print('❌ [SessionManager] Erro ao decodificar usuário: $e');
      return null;
    }
  }

  /// Verifica se existe uma sessão ativa
  Future<bool> hasActiveSession() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && token.isNotEmpty && user != null;
  }

  /// Limpa toda a sessão
  Future<void> clearSession() async {
    await _secureStorage.delete(_tokenKey);
    await _secureStorage.delete(_deviceIdKey);
    await _storage.remove(_userKey);
  }

  /// Garante que este método NÃO faz chamada de rede
  Future<UserModel?> getLocalSession() async {
    return await getUser();
  }

  /// Verifica se existe sessão local sem validação remota
  Future<bool> hasLocalSession() async {
    return (await getLocalSession()) != null;
  }
}
