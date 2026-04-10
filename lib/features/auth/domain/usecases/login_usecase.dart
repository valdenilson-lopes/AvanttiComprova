import 'package:dartz/dartz.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/core/errors/failures.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> execute(
    String cnpj,
    String motorista,
    String deviceId,
  ) async {
    print('🔐 [LOGIN_USECASE] Login unificado');
    print('   - CNPJ: $cnpj');
    print('   - Motorista: $motorista');
    print('   - DeviceId: $deviceId');

    final startTime = DateTime.now();

    final result = await repository.login(cnpj, motorista, deviceId);

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;

    result.fold(
      (failure) => print(
          '❌ [LOGIN_USECASE] Falha após ${elapsed}ms: ${failure.message}'),
      (user) =>
          print('✅ [LOGIN_USECASE] Sucesso após ${elapsed}ms: ${user.nome}'),
    );

    return result;
  }
}
