import 'package:dartz/dartz.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/features/enterprise/data/datasources/enterprise_local_datasource.dart';
import 'package:app/features/enterprise/data/models/enterprise_model.dart';
import 'package:app/core/errors/failures.dart';

class EnterpriseRepositoryImpl implements EnterpriseRepository {
  final EnterpriseLocalDataSource _localDataSource;

  EnterpriseRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<Enterprise>>> getEnterprises() async {
    final result = await _localDataSource.getEnterprises();

    return result.fold(
      (failure) => Left(failure),
      (models) => Right(models.map((e) => e.toEntity()).toList()),
    );
  }

  @override
  Future<Either<Failure, Enterprise?>> getCurrentEnterprise() async {
    final cnpjResult = await _localDataSource.getCurrentEnterpriseCnpj();

    return cnpjResult.fold((failure) => Left(failure), (cnpj) async {
      if (cnpj == null) return const Right(null);

      final enterprisesResult = await getEnterprises();

      return enterprisesResult.fold((failure) => Left(failure), (enterprises) {
        try {
          final enterprise = enterprises.firstWhere((e) => e.cnpj == cnpj);
          return Right(enterprise);
        } catch (_) {
          return const Right(null);
        }
      });
    });
  }

  @override
  Future<Either<Failure, void>> saveEnterprise(Enterprise enterprise) async {
    final model = EnterpriseModel.fromEntity(enterprise);
    return await _localDataSource.saveEnterprise(model);
  }

  @override
  Future<Either<Failure, void>> removeEnterprise(String cnpj) async {
    return await _localDataSource.removeEnterprise(cnpj);
  }

  @override
  Future<Either<Failure, void>> selectEnterprise(String cnpj) async {
    return await _localDataSource.setCurrentEnterpriseCnpj(cnpj);
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    return await _localDataSource.clearAll();
  }
}
