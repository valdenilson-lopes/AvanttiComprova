import 'package:dartz/dartz.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';
import 'package:app/core/errors/failures.dart';

class ValidarSessaoUseCase {
  final AuthRepository repository;

  ValidarSessaoUseCase(this.repository);

  Future<Either<Failure, SessionValidationResult>> execute(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  }) async {
    print('🔍 [VALIDAR_SESSAO_USECASE] Validando sessão');
    return await repository.validarSessao(cnpj, motorista,
        token: token, deviceId: deviceId);
  }
}
