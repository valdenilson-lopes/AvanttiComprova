import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/app/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/services/session_manager.dart';

class AuthController {
  final LogoutUseCase _logoutUseCase;
  String? _lastLogoutMessage;

  AuthController(this._logoutUseCase);

  String? get lastLogoutMessage => _lastLogoutMessage;

  void setLastLogoutMessage(String? message) {
    _lastLogoutMessage = message;
  }

  void clearLastLogoutMessage() {
    _lastLogoutMessage = null;
  }

  Future<void> logout() async {
    print('🚪 [AuthController] Logout solicitado');
    await _logoutUseCase.execute();
    _redirectToLogin();
  }

  Future<void> onUnauthorized([BuildContext? context]) async {
    print('🔐 [AuthController] 401 - Sessão não autorizada');
    await _logoutUseCase.execute();

    // Se temos um contexto, usamos ele
    if (context != null) {
      AppRoutes.popToLogin(context);
    } else {
      _redirectToLogin();
    }
  }

  Future<void> forceLogout() async {
    print('🔐 [AuthController] Force logout');
    await _logoutUseCase.execute();
    _redirectToLogin();
  }

  void _redirectToLogin() {
    print('🔀 [AuthController] Redirecionando para login');

    final navigatorKey = getIt<GlobalKey<NavigatorState>>();

    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteNames.login,
        (route) => false,
      );
    } else {
      print('⚠️ [AuthController] navigatorKey.currentState é null');
    }
  }

  Future<bool> isAuthenticated() async {
    final sessionManager = getIt<SessionManager>();
    return await sessionManager.hasActiveSession();
  }
}
