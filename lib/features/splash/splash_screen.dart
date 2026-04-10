import 'package:flutter/material.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/services/session_manager.dart';
import 'package:app/app/app_routes.dart';
import 'dart:developer';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Constants for better maintainability
  static const Duration _splashDuration = Duration(milliseconds: 1500);
  static const Duration _navigationDelay = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    print('═══════════════════════════════════════════════════════');
    print('🟢 [SPLASH] initState iniciado');
    print('═══════════════════════════════════════════════════════');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _checkAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    // Aguarda um pouco para a animação
    await Future.delayed(_splashDuration);

    final sessionManager = getIt<SessionManager>();
    final hasSession = await sessionManager.hasLocalSession();

    print('🔍 [SPLASH] Sessão local existe: $hasSession');

    if (!mounted) return;

    if (hasSession) {
      // Vai para Home mesmo offline
      print('🚀 [SPLASH] Navegando para HOME');
      AppRoutes.pushToHome(context);
    } else {
      // Primeiro acesso precisa de internet
      print('🚀 [SPLASH] Navegando para LOGIN');
      AppRoutes.pushToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/icon.png', height: 120),
                const SizedBox(height: 24),
                const Text(
                  'Avantti Comprova',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
