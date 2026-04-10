import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/errors/failures.dart';

class GetEnterprisesUseCase {
  final EnterpriseRepository repository;

  GetEnterprisesUseCase(this.repository);

  Future<Either<Failure, List<Enterprise>>> execute() {
    return repository.getEnterprises();
  }
}
