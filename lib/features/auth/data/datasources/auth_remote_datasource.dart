import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';

/// Interface para o DataSource remoto de autenticação
abstract class AuthRemoteDataSource {
  /// Realiza o login unificado do motorista com deviceId
  Future<Either<Failure, UserModel>> login(
    String cnpj,
    String motorista,
    String deviceId,
  );

  /// Valida se a sessão atual ainda é permitida
  /// Retorna um resultado detalhado com o motivo da invalidação
  Future<Either<Failure, SessionValidationResult>> validarSessao(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  });

  /// Remove a sessão ativa do motorista
  Future<Either<Failure, void>> logout(String cnpj, String motorista);

  /// Atualiza o timestamp de último acesso para manter a licença ativa
  Future<Either<Failure, void>> atualizarUltimoAcesso(
    String cnpj,
    String motorista,
  );
}
