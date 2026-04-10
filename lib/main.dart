import 'package:flutter/material.dart';
import 'package:app/app/app.dart';
import 'package:app/config/env.dart';
import 'package:app/config/api_config.dart';
import 'package:app/core/di/injector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega ambiente (dev/homolog/prod)
  await Env.load();

  // 2. 🔥 INICIALIZA SUPABASE ANTES DO SETUP
  await Supabase.initialize(
    url: ApiConfig.baseUrl,
    anonKey: ApiConfig.anonKey,
  );

  // 3. Setup DI (agora o Supabase já está disponível)
  await setupInjector();

  runApp(const App());
}
