import 'package:dartz/dartz.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/core/errors/failures.dart';

class GetSessionUseCase {
  final AuthRepository repository;

  GetSessionUseCase(this.repository);

  /// Apenas local — NÃO valida com backend na Fase 4A
  Future<Either<Failure, User?>> execute() {
    return repository.getLocalSession();
  }
}
