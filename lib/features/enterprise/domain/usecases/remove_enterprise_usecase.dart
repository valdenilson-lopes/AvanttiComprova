import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/core/errors/failures.dart';

class RemoveEnterpriseUseCase {
  final EnterpriseRepository repository;

  RemoveEnterpriseUseCase(this.repository);

  Future<Either<Failure, void>> execute(String cnpj) {
    return repository.removeEnterprise(cnpj);
  }
}
