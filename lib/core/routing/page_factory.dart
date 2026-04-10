import 'package:flutter/material.dart';
import 'package:app/features/splash/splash_screen.dart';
import 'package:app/features/auth/presentation/pages/login_screen.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/features/menu/menu_screen.dart';
import 'package:app/core/routing/route_arguments.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/features/enterprise/presentation/pages/enterprise_page.dart';

class PageFactory {
  static Widget splash() => const SplashScreen();

  static Widget login(Object? args) {
    final loginArgs = RouteUtils.getLoginArguments(args);
    return LoginScreen(
      initialCnpj: loginArgs?.initialCnpj,
      autoFocus: loginArgs?.autoFocus ?? false,
    );
  }

  static Widget home(Object? args) {
    final homeArgs = RouteUtils.getHomeArguments(args);
    return HomeScreen(
      showWelcomeMessage: homeArgs?.showWelcomeMessage ?? false,
    );
  }

  static Widget enterprises(Object? args) {
    final enterprisesArgs = RouteUtils.getEnterprisesArguments(args);
    return EnterprisePage(
      mode: enterprisesArgs?.mode ?? EnterpriseMode.select,
    );
  }

  static Widget menu() => const MenuScreen();
}
