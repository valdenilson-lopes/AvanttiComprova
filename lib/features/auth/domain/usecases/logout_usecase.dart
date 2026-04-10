import 'package:dartz/dartz.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/errors/failures.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.logout();
  }
}
