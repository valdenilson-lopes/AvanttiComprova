import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';

// Argumentos para tela de empresas
class EnterprisesArguments {
  final EnterpriseMode mode;

  EnterprisesArguments({required this.mode});
}

// Argumentos para tela de login
class LoginArguments {
  final String? initialCnpj;
  final bool autoFocus;

  LoginArguments({this.initialCnpj, this.autoFocus = false});
}

// Argumentos para tela home
class HomeArguments {
  final bool showWelcomeMessage;

  HomeArguments({this.showWelcomeMessage = false});
}

// Utility para extrair argumentos de forma segura
class RouteUtils {
  // Versão corrigida - especificando que T deve ser um tipo
  static T? getArgument<T>(Object? arguments) {
    if (arguments == null) return null;
    if (arguments is T) return arguments as T; // Cast explícito
    return null;
  }

  static EnterprisesArguments? getEnterprisesArguments(Object? arguments) {
    return getArgument<EnterprisesArguments>(arguments);
  }

  static LoginArguments? getLoginArguments(Object? arguments) {
    return getArgument<LoginArguments>(arguments);
  }

  static HomeArguments? getHomeArguments(Object? arguments) {
    return getArgument<HomeArguments>(arguments);
  }
}
