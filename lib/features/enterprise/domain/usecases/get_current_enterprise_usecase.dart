import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/errors/failures.dart';

class GetCurrentEnterpriseUseCase {
  final EnterpriseRepository repository;

  GetCurrentEnterpriseUseCase(this.repository);

  Future<Either<Failure, Enterprise?>> execute() {
    return repository.getCurrentEnterprise();
  }
}
