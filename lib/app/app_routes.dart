import 'package:flutter/material.dart';
import 'package:app/core/routing/page_factory.dart';
import 'package:app/core/routing/route_arguments.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';

// Definição dos nomes das rotas
class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String enterprises = '/empresas';
  static const String menu = '/menu';
}

class AppRoutes {
  static Map<String, WidgetBuilder> get routes {
    return {
      RouteNames.splash: (context) => PageFactory.splash(),
      RouteNames.login: (context) =>
          PageFactory.login(ModalRoute.of(context)?.settings.arguments),
      RouteNames.home: (context) =>
          PageFactory.home(ModalRoute.of(context)?.settings.arguments),
      RouteNames.enterprises: (context) =>
          PageFactory.enterprises(ModalRoute.of(context)?.settings.arguments),
      RouteNames.menu: (context) => PageFactory.menu(),
    };
  }

  static Future<T?> pushToLogin<T>(
    BuildContext context, {
    String? initialCnpj,
    bool autoFocus = false,
  }) {
    return Navigator.pushNamed(
      context,
      RouteNames.login,
      arguments: LoginArguments(initialCnpj: initialCnpj, autoFocus: autoFocus),
    );
  }

  static Future<T?> pushToHome<T>(
    BuildContext context, {
    bool showWelcomeMessage = false,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      RouteNames.home,
      arguments: HomeArguments(showWelcomeMessage: showWelcomeMessage),
    );
  }

  static Future<T?> pushToEnterprises<T>(
    BuildContext context, {
    required EnterpriseMode mode,
  }) {
    return Navigator.pushNamed(
      context,
      RouteNames.enterprises,
      arguments: EnterprisesArguments(mode: mode),
    );
  }

  static Future<T?> pushToEnterprisesAndRemoveUntil<T>(
    BuildContext context, {
    required EnterpriseMode mode,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.enterprises,
      (route) => false,
      arguments: EnterprisesArguments(mode: mode),
    );
  }

  static void popToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }
}
