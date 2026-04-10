import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/errors/failures.dart';

class SaveEnterpriseUseCase {
  final EnterpriseRepository repository;

  SaveEnterpriseUseCase(this.repository);

  Future<Either<Failure, void>> execute(Enterprise enterprise) {
    return repository.saveEnterprise(enterprise);
  }
}
