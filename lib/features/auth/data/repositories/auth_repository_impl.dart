import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';
import 'package:app/services/session_manager.dart';
import 'package:app/core/di/injector.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  late final SessionManager _sessionManager;

  AuthRepositoryImpl({
    required this.remote,
    required this.local,
  }) {
    _sessionManager = getIt<SessionManager>();
  }

  @override
  Future<Either<Failure, User>> login(
    String cnpj,
    String motorista,
    String deviceId,
  ) async {
    print('🔐 [AuthRepository] Login unificado');
    print('   - CNPJ: $cnpj');
    print('   - Motorista: $motorista');
    print('   - DeviceId: $deviceId');

    final result = await remote.login(cnpj, motorista, deviceId);

    return result.fold(
      (failure) {
        print('❌ [AuthRepository] Login falhou: ${failure.message}');
        return Left(failure);
      },
      (userModel) async {
        print('✅ [AuthRepository] Login bem-sucedido');
        print('   - Usuário: ${userModel.nome}');
        print(
            '   - Token presente: ${userModel.token != null ? "SIM" : "NÃO"}');

        // Salva o user (SEM TOKEN) no local datasource
        final userWithoutToken = userModel.copyWith(token: null);
        final saveResult = await local.saveSession(userWithoutToken, cnpj);

        if (saveResult.isLeft()) {
          final failure = saveResult.fold((f) => f, (_) => null);
          print(
              '❌ [AuthRepository] Erro ao salvar usuário: ${failure?.message}');
          return Left(failure ?? CacheFailure('Erro ao salvar sessão'));
        }

        // Salva token e deviceId no SessionManager (SecureStorage)
        if (userModel.token != null && userModel.token!.isNotEmpty) {
          await _sessionManager.saveSession(userModel);
          print('✅ [AuthRepository] Token salvo no SecureStorage');
        }

        print('✅ [AuthRepository] Sessão salva com sucesso');
        return Right(userModel.toEntity());
      },
    );
  }

  @override
  Future<Either<Failure, void>> logout() async {
    print('🚪 [AuthRepository] Logout iniciado');

    final sessionResult = await local.getSession();

    return sessionResult.fold(
      (failure) async {
        print(
            '⚠️ [AuthRepository] Não foi possível obter sessão: ${failure.message}');
        await local.clearSession();
        await _sessionManager.clearSession();
        return const Right(null);
      },
      (userModel) async {
        if (userModel != null &&
            userModel.cnpj != null &&
            userModel.motorista != null) {
          print('   - Encerrando sessão no servidor');
          await remote.logout(userModel.cnpj!, userModel.motorista!);
        }

        await local.clearSession();
        await _sessionManager.clearSession();
        print('✅ [AuthRepository] Logout concluído');
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, User?>> getSession() async {
    print('🔍 [AuthRepository] Recuperando sessão');

    final userResult = await local.getSession();

    return userResult.fold(
      (failure) {
        print(
            '❌ [AuthRepository] Falha ao recuperar usuário: ${failure.message}');
        return Left(failure);
      },
      (userModel) async {
        if (userModel == null) {
          print('⚠️ [AuthRepository] Nenhum usuário encontrado');
          return const Right(null);
        }

        final sessionData = await _sessionManager.getFullSession();

        if (sessionData != null) {
          print(
              '✅ [AuthRepository] Token e DeviceId recuperados do SecureStorage');
          final userWithToken = userModel.copyWith(
            token: sessionData['token'],
            deviceId: sessionData['deviceId'],
          );
          return Right(userWithToken.toEntity());
        } else {
          print('⚠️ [AuthRepository] Nenhum token encontrado');
          return const Right(null);
        }
      },
    );
  }

  @override
  Future<Either<Failure, SessionValidationResult>> validarSessao(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  }) async {
    print('🔍 [AuthRepository] Validando sessão');
    print('   - CNPJ: $cnpj');
    print('   - Motorista: $motorista');

    String? effectiveToken = token;
    String? effectiveDeviceId = deviceId;

    if (effectiveToken == null || effectiveDeviceId == null) {
      final sessionData = await _sessionManager.getFullSession();
      effectiveToken ??= sessionData?['token'];
      effectiveDeviceId ??= sessionData?['deviceId'];
    }

    final result = await remote.validarSessao(
      cnpj,
      motorista,
      token: effectiveToken,
      deviceId: effectiveDeviceId,
    );

    return result.fold(
      (failure) {
        print('❌ [AuthRepository] Erro ao validar sessão: ${failure.message}');
        return Left(failure);
      },
      (validationResult) async {
        if (!validationResult.isValid) {
          print(
              '⚠️ [AuthRepository] Sessão inválida - Motivo: ${validationResult.reason}');
          print('   - Detalhes: ${validationResult.detalhes}');
          print('   - Mensagem: ${validationResult.mensagemAmigavel}');

          // 🔥 Limpa sessão local APENAS se não for "replacedByAnotherDevice"
          // porque nesse caso o app vai fazer logout automático anyway
          if (validationResult.reason !=
              SessionInvalidReason.replacedByAnotherDevice) {
            await local.clearSession();
            await _sessionManager.clearSession();
          }
        } else {
          print('✅ [AuthRepository] Sessão válida');
        }
        return Right(validationResult);
      },
    );
  }

  @override
  Future<Either<Failure, void>> atualizarUltimoAcesso(
    String cnpj,
    String motorista,
  ) async {
    print('🔄 [AuthRepository] Atualizando último acesso');
    return remote.atualizarUltimoAcesso(cnpj, motorista);
  }

  @override
  Future<Either<Failure, User?>> getLocalSession() async {
    try {
      final user = await _sessionManager.getLocalSession();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure('Erro ao carregar sessão local: $e'));
    }
  }
}
