import 'package:flutter/material.dart';
import 'package:app/app/app_theme.dart';
import 'package:app/app/app_routes.dart';
import 'package:app/core/di/injector.dart';

// 🔥 Chave global para navegação (usada pelo HttpClient para logout)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Registra a navigatorKey no injector para acesso global
    if (!getIt.isRegistered<GlobalKey<NavigatorState>>()) {
      getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);
    }

    return MaterialApp(
      navigatorKey: navigatorKey, // 🔥 USAR A CHAVE GLOBAL
      debugShowCheckedModeBanner: false,
      title: 'Avantti Comprova',
      theme: appTheme,
      initialRoute: RouteNames.splash,
      routes: AppRoutes.routes,
    );
  }
}
