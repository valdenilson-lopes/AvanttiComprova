import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';

abstract class AuthRepository {
  // Método único para login com deviceId
  Future<Either<Failure, User>> login(
    String cnpj,
    String motorista,
    String deviceId,
  );

  // Gerenciamento de sessão
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getSession();

  // Validação de sessão com resultado detalhado
  Future<Either<Failure, SessionValidationResult>> validarSessao(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  });

  Future<Either<Failure, void>> atualizarUltimoAcesso(
    String cnpj,
    String motorista,
  );

  Future<Either<Failure, User?>> getLocalSession();
}
