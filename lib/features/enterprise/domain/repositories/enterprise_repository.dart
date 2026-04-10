import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/errors/failures.dart';

abstract class EnterpriseRepository {
  Future<Either<Failure, List<Enterprise>>> getEnterprises();
  Future<Either<Failure, Enterprise?>> getCurrentEnterprise();
  Future<Either<Failure, void>> saveEnterprise(Enterprise enterprise);
  Future<Either<Failure, void>> removeEnterprise(String cnpj);
  Future<Either<Failure, void>> selectEnterprise(String cnpj);
  Future<Either<Failure, void>> clearAll();
}
