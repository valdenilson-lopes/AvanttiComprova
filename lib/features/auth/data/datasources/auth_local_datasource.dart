import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  /// 🔥 IMPORTANTE: user NÃO deve conter token!
  Future<Either<Failure, void>> saveSession(UserModel user, String cnpj);
  Future<Either<Failure, UserModel?>> getSession();
  Future<Either<Failure, void>> clearSession();
  Future<Either<Failure, String?>> getLastCnpj();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final IStorageService _storage;

  static const _userKey = 'auth_user';
  static const _cnpjKey = 'last_cnpj';

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<Either<Failure, void>> saveSession(UserModel user, String cnpj) async {
    try {
      print('💾 [AuthLocal] Salvando sessão (SEM TOKEN)');
      print('   - CNPJ: $cnpj');
      print('   - Usuário: ${user.nome}');
      print('   - Motorista: ${user.motorista}');
      print('   - ID: ${user.id}');
      print('   - Token presente: ${user.token != null ? "SIM" : "NÃO"}');

      // 🔥 CRÍTICO: Usar toJson() que NÃO inclui o token
      final userJson = jsonEncode(user.toJson());
      await _storage.writeString(_userKey, userJson);
      await _storage.writeString(_cnpjKey, cnpj);

      print(
          '✅ [AuthLocal] Sessão salva com sucesso (token NÃO foi salvo aqui)');
      return const Right(null);
    } catch (e) {
      print('❌ [AuthLocal] Erro ao salvar sessão: $e');
      return Left(CacheFailure('Erro ao salvar sessão: $e'));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getSession() async {
    try {
      final userJson = await _storage.readString(_userKey);
      final cnpj = await _storage.readString(_cnpjKey);

      print('🔍 [AuthLocal] Recuperando sessão');
      print('   - User JSON exists: ${userJson != null}');
      print('   - CNPJ: $cnpj');

      if (userJson == null) {
        print('⚠️ [AuthLocal] Nenhum usuário encontrado');
        return const Right(null);
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      // 🔥 O token NÃO está no JSON (foi removido pelo toJson)
      final user = UserModel.fromJson(userMap);

      print('✅ [AuthLocal] Sessão recuperada: ${user.nome}');
      print('   - Token no JSON: ${user.token != null ? "SIM" : "NÃO"}');
      return Right(user);
    } catch (e) {
      print('❌ [AuthLocal] Erro ao recuperar sessão: $e');
      return Left(CacheFailure('Erro ao recuperar sessão: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearSession() async {
    try {
      await _storage.remove(_userKey);
      await _storage.remove(_cnpjKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erro ao limpar sessão: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getLastCnpj() async {
    try {
      final cnpj = await _storage.readString(_cnpjKey);
      return Right(cnpj);
    } catch (e) {
      return Left(CacheFailure('Erro ao recuperar último CNPJ: $e'));
    }
  }
}
