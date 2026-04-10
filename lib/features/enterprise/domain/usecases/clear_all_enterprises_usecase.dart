import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/core/errors/failures.dart';

class ClearAllEnterprisesUseCase {
  final EnterpriseRepository repository;

  ClearAllEnterprisesUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.clearAll();
  }
}
