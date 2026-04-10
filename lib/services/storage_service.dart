import 'package:shared_preferences/shared_preferences.dart';

abstract class IStorageService {
  // Métodos genéricos
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);

  // Métodos para tipos específicos
  Future<void> setBool(String key, bool value);
  bool? getBool(String key);
  Future<void> setInt(String key, int value);
  int? getInt(String key);

  // 🔥 ALIAS para compatibilidade (mesmo que setString/getString)
  Future<void> writeString(String key, String value);
  Future<String?> readString(String key);
}

class StorageServiceImpl implements IStorageService {
  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // 🔥 Implementação dos aliases
  @override
  Future<void> writeString(String key, String value) async {
    await setString(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    return getString(key);
  }
}
