import 'package:shared_preferences/shared_preferences.dart';

enum Environment { dev, homolog, prod }

class Env {
  static Environment current = Environment.dev;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("env");

    print('📦 Env salvo: $saved');
    if (saved != null) {
      current = Environment.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => Environment.dev,
      );
    }

    print('🎯 Ambiente atual: $current');
  }

  static Future<void> set(Environment env) async {
    current = env;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("env", env.name);
    print('✅ Ambiente alterado para: $env');
  }
}
