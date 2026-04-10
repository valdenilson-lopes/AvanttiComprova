import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/models/license_model.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';
import 'package:flutter/foundation.dart';

class AuthSupabaseDataSource implements AuthRemoteDataSource {
  // 🔥 CLIENTE LAZY - só inicializa quando for usado pela primeira vez
  SupabaseClient? _supabaseClient;

  /// Getter que garante a inicialização correta do Supabase
  SupabaseClient get _supabase {
    if (_supabaseClient == null) {
      // 🔥 VERIFICA SE O SUPABASE FOI INICIALIZADO NO MAIN
      if (!Supabase.instance.isInitialized) {
        throw StateError(
          'Supabase não foi inicializado corretamente.\n'
          'Certifique-se de que Supabase.initialize() foi chamado no main.dart '
          'e que o "await" foi utilizado antes de configurar o Injector.',
        );
      }
      _supabaseClient = Supabase.instance.client;
    }
    return _supabaseClient!;
  }

  @override
  Future<Either<Failure, UserModel>> login(
    String cnpj,
    String motorista,
    String deviceId,
  ) async {
    _logSensitive('🔐 [AuthSupabase] Login via RPC', cnpj, motorista);
    _log('   - DeviceId: ${_maskDeviceId(deviceId)}');

    try {
      final response = await _supabase.rpc('login', params: {
        'p_cnpj': cnpj,
        'p_motorista': motorista,
        'p_device_id': deviceId,
      });

      _log('✅ [AuthSupabase] Login bem-sucedido');

      final userData = response['user'] as Map<String, dynamic>;
      final licenseData = response['license'] as Map<String, dynamic>;

      return Right(UserModel(
        id: userData['id'].toString(),
        nome: userData['nome'] as String,
        nomeEmpresa: userData['nome_empresa'] as String?,
        motorista: userData['motorista'] as String?,
        cnpj: userData['cnpj'] as String?,
        token: response['token'] as String?,
        deviceId: deviceId,
        license: LicenseModel(
          limite: licenseData['limite'] as int,
          emUso: licenseData['emUso'] as int,
          expiraEm: DateTime.parse(licenseData['expiraEm'] as String),
          valida: true,
        ),
      ));
    } on PostgrestException catch (e) {
      _log('❌ [AuthSupabase] Erro Postgrest: ${_maskError(e.message)}');
      return Left(_mapErrorMessageToFailure(e.message));
    } catch (e) {
      _log('❌ [AuthSupabase] Erro crítico: $e');
      return Left(ServerFailure('Erro de comunicação: $e'));
    }
  }

  @override
  Future<Either<Failure, SessionValidationResult>> validarSessao(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  }) async {
    _log('🔍 [AuthSupabase] Validando sessão');

    try {
      final result = await _supabase.rpc('validar_sessao', params: {
        'p_token': token ?? '',
      });

      SessionValidationResult validationResult;

      if (result is Map<String, dynamic>) {
        final isValid = result['valida'] as bool? ?? false;
        final motivo = result['motivo'] as String?;
        final detalhes = result['detalhes'] as String?;

        final reason = _mapStringToReason(motivo);
        validationResult = SessionValidationResult(
          isValid: isValid,
          reason: reason,
          detalhes: detalhes,
        );
      } else if (result is bool) {
        validationResult = SessionValidationResult(
          isValid: result,
          reason:
              result ? SessionInvalidReason.none : SessionInvalidReason.expired,
        );
      } else {
        validationResult = SessionValidationResult(
          isValid: false,
          reason: SessionInvalidReason.expired,
        );
      }

      _log(
          '✅ [AuthSupabase] Sessão ${validationResult.isValid ? "válida" : "inválida"}');
      return Right(validationResult);
    } on PostgrestException catch (e) {
      _log('❌ [AuthSupabase] Erro na validação: ${_maskError(e.message)}');
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    } catch (e) {
      _log('❌ [AuthSupabase] Erro crítico na validação: $e');
      return Left(ServerFailure('Erro ao validar sessão: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout(String cnpj, String motorista) async {
    _log('🚪 [AuthSupabase] Logout solicitado');

    try {
      await _supabase.rpc('logout', params: {
        'p_cnpj': cnpj,
        'p_motorista': motorista,
      });
      _log('✅ [AuthSupabase] Logout realizado');
      return const Right(null);
    } on PostgrestException catch (e) {
      _log('❌ [AuthSupabase] Erro no logout: ${_maskError(e.message)}');
      return Left(ServerFailure('Erro no logout: ${e.message}'));
    } catch (e) {
      _log('❌ [AuthSupabase] Erro crítico no logout: $e');
      return Left(ServerFailure('Erro no logout: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> atualizarUltimoAcesso(
    String cnpj,
    String motorista,
  ) async {
    try {
      await _supabase.rpc('atualizar_ultimo_acesso', params: {
        'p_cnpj': cnpj,
        'p_motorista': motorista,
      });
      return const Right(null);
    } catch (e) {
      _log('❌ [AuthSupabase] Erro ao atualizar acesso: $e');
      return Left(ServerFailure('Erro ao atualizar acesso: $e'));
    }
  }

  // --- Métodos Auxiliares ---

  SessionInvalidReason _mapStringToReason(String? reason) {
    switch (reason) {
      case 'sessao_nao_encontrada':
        return SessionInvalidReason.notFound;
      case 'substituida_outro_dispositivo':
        return SessionInvalidReason.replacedByAnotherDevice;
      case 'timeout':
        return SessionInvalidReason.timeout;
      case 'logout_manual':
        return SessionInvalidReason.logoutManual;
      case 'sessao_encerrada':
        return SessionInvalidReason.revoked;
      case 'license_limit':
        return SessionInvalidReason.licenseLimit;
      default:
        return SessionInvalidReason.expired;
    }
  }

  Failure _mapErrorMessageToFailure(String message) {
    if (message.contains('Empresa não encontrada'))
      return NotFoundFailure(message);
    if (message.contains('Motorista inválido'))
      return const InvalidCredentialsFailure();
    if (message.contains('Licença')) return LicencaExpiradaFailure(message);
    if (message.contains('Limite') || message.contains('outro dispositivo')) {
      return LimiteUsuariosFailure(message);
    }
    return ServerFailure(message);
  }

  void _log(String message) {
    if (kDebugMode) print(message);
  }

  void _logSensitive(String prefix, String cnpj, String motorista) {
    if (kDebugMode) {
      print(
          '$prefix - CNPJ: ${_maskCnpj(cnpj)} | Motorista: ${_maskMotorista(motorista)}');
    }
  }

  String _maskCnpj(String cnpj) => cnpj.length < 8
      ? '***'
      : '${cnpj.substring(0, 5)}******${cnpj.substring(cnpj.length - 3)}';
  String _maskMotorista(String motorista) => motorista.length < 3
      ? '***'
      : '${motorista.substring(0, 1)}***${motorista.substring(motorista.length - 1)}';
  String _maskDeviceId(String deviceId) => deviceId.length < 10
      ? '***'
      : '${deviceId.substring(0, 6)}...${deviceId.substring(deviceId.length - 4)}';
  String _maskError(String message) =>
      message.replaceAllMapped(RegExp(r'\d{14}'), (match) => '***');
}
