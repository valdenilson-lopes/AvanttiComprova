import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/enterprise/data/models/enterprise_model.dart';
import 'dart:convert';

abstract class EnterpriseLocalDataSource {
  Future<Either<Failure, List<EnterpriseModel>>> getEnterprises();
  Future<Either<Failure, void>> saveEnterprise(EnterpriseModel enterprise);
  Future<Either<Failure, void>> saveAllEnterprises(
    List<EnterpriseModel> enterprises,
  );
  Future<Either<Failure, void>> removeEnterprise(String cnpj);
  Future<Either<Failure, String?>> getCurrentEnterpriseCnpj();
  Future<Either<Failure, void>> setCurrentEnterpriseCnpj(String cnpj);
  Future<Either<Failure, void>> clearAll();

  // Métodos específicos para cache offline-first
  Future<List<EnterpriseModel>> getCachedEnterprises();
  Future<EnterpriseModel?> getCurrentEnterprise();
  Future<void> cacheEnterprises(List<EnterpriseModel> enterprises);
}

class EnterpriseLocalDataSourceImpl implements EnterpriseLocalDataSource {
  final IStorageService _storage;

  static const _enterprisesKey = 'empresas';
  static const _currentEnterpriseKey = 'empresa_ativa';

  EnterpriseLocalDataSourceImpl(this._storage);

  @override
  Future<Either<Failure, List<EnterpriseModel>>> getEnterprises() async {
    try {
      final jsonString = await _storage.readString(_enterprisesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return const Right([]);
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final enterprises = jsonList
          .map((e) => EnterpriseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(enterprises);
    } catch (e) {
      return Left(CacheFailure('Erro ao carregar empresas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveEnterprise(
    EnterpriseModel enterprise,
  ) async {
    try {
      final result = await getEnterprises();

      return result.fold((failure) => Left(failure), (enterprises) async {
        final mutableEnterprises = List<EnterpriseModel>.from(enterprises);

        // Remove se já existe
        mutableEnterprises.removeWhere((e) => e.cnpj == enterprise.cnpj);
        // Adiciona a nova
        mutableEnterprises.add(enterprise);

        return await saveAllEnterprises(mutableEnterprises);
      });
    } catch (e) {
      return Left(CacheFailure('Erro ao salvar empresa: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAllEnterprises(
    List<EnterpriseModel> enterprises,
  ) async {
    try {
      final jsonString = jsonEncode(
        enterprises.map((e) => e.toJson()).toList(),
      );
      await _storage.writeString(_enterprisesKey, jsonString);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erro ao salvar empresas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeEnterprise(String cnpj) async {
    try {
      final result = await getEnterprises();

      return result.fold((failure) => Left(failure), (enterprises) async {
        final mutableEnterprises = List<EnterpriseModel>.from(enterprises);
        mutableEnterprises.removeWhere((e) => e.cnpj == cnpj);
        return await saveAllEnterprises(mutableEnterprises);
      });
    } catch (e) {
      return Left(CacheFailure('Erro ao remover empresa: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getCurrentEnterpriseCnpj() async {
    try {
      final cnpj = await _storage.readString(_currentEnterpriseKey);
      return Right(cnpj);
    } catch (e) {
      return Left(CacheFailure('Erro ao recuperar empresa ativa: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setCurrentEnterpriseCnpj(String cnpj) async {
    try {
      await _storage.writeString(_currentEnterpriseKey, cnpj);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erro ao definir empresa ativa: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _storage.remove(_enterprisesKey);
      await _storage.remove(_currentEnterpriseKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erro ao limpar dados: $e'));
    }
  }

  @override
  Future<List<EnterpriseModel>> getCachedEnterprises() async {
    try {
      final jsonString = await _storage.readString(_enterprisesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => EnterpriseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [EnterpriseLocalDataSource] Erro ao carregar cache: $e');
      return [];
    }
  }

  @override
  Future<EnterpriseModel?> getCurrentEnterprise() async {
    try {
      final cnpj = await _storage.readString(_currentEnterpriseKey);
      if (cnpj == null) return null;

      final enterprises = await getCachedEnterprises();
      return enterprises.firstWhere(
        (e) => e.cnpj == cnpj,
        orElse: () => throw Exception('Empresa não encontrada'),
      );
    } catch (e) {
      print('❌ [EnterpriseLocalDataSource] Erro ao carregar empresa atual: $e');
      return null;
    }
  }

  @override
  Future<void> cacheEnterprises(List<EnterpriseModel> enterprises) async {
    try {
      final jsonString = jsonEncode(
        enterprises.map((e) => e.toJson()).toList(),
      );
      await _storage.writeString(_enterprisesKey, jsonString);
    } catch (e) {
      print('❌ [EnterpriseLocalDataSource] Erro ao salvar cache: $e');
    }
  }
}
