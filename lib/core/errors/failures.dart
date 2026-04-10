import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Erros de Rede / Servidor ---

class ServerFailure extends Failure {
  final int? statusCode;
  // Usando super.message para repassar a String ao pai
  const ServerFailure(super.message, {this.statusCode});
}

class ConnectionFailure extends Failure {
  // Agora aceita uma mensagem customizada, resolvendo o erro de "Too many positional arguments"
  const ConnectionFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Tempo limite excedido'])
      : super(message);
}

// --- Erros de Autenticação ---

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(
      [String message = 'CNPJ ou motorista inválidos'])
      : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Não autorizado'])
      : super(message);
}

// --- Erros de Cache ---

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// --- Erros de Validação ---

class ValidationFailure extends Failure {
  final Map<String, String>? errors;
  const ValidationFailure(super.message, {this.errors});
}

// --- Erros Específicos de Negócio ---

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class LicencaExpiradaFailure extends Failure {
  const LicencaExpiradaFailure([String message = 'Licença expirada'])
      : super(message);
}

class LimiteUsuariosFailure extends Failure {
  const LimiteUsuariosFailure([String message = 'Limite de usuários atingido'])
      : super(message);
}
