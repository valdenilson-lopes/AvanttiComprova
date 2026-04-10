import 'dart:async';
import 'package:app/services/session_manager.dart';
import 'package:app/features/auth/domain/usecases/validar_sessao_usecase.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';
import 'package:app/core/utils/internet_checker.dart';
import 'package:flutter/foundation.dart';

class SessionRefreshService {
  static final SessionRefreshService _instance =
      SessionRefreshService._internal();

  static SessionRefreshService get instance => _instance;

  // Dependências (injetadas uma vez)
  late final SessionManager _sessionManager;
  late final ValidarSessaoUseCase _validarSessaoUseCase;
  late final AuthController _authController;
  late final AuthRepository _authRepository;
  final InternetChecker _internetChecker = InternetChecker();

  Timer? _validationTimer;
  Timer? _lastAccessTimer;

  bool _isValidating = false;
  bool _isLoggingOut = false;
  bool _isStarted = false; // 🔥 CONTROLE DE ESTADO
  int _startCount = 0; // 🔥 PARA DEBUG

  static const Duration VALIDATION_INTERVAL = Duration(seconds: 30);
  static const Duration LAST_ACCESS_INTERVAL = Duration(minutes: 2);

  SessionRefreshService._internal();

  /// 🔥 INICIALIZAÇÃO OBRIGATÓRIA (chamar uma vez no main ou injector)
  void init({
    required SessionManager sessionManager,
    required ValidarSessaoUseCase validarSessaoUseCase,
    required AuthController authController,
    required AuthRepository authRepository,
  }) {
    _sessionManager = sessionManager;
    _validarSessaoUseCase = validarSessaoUseCase;
    _authController = authController;
    _authRepository = authRepository;
    _log('✅ [SessionRefreshService] Inicializado');
  }

  /// 🔥 START SEGURO - só inicia se não estiver rodando
  void start() {
    if (!_isInitialized) {
      _log(
          '⚠️ [SessionRefreshService] Serviço não inicializado. Chame init() primeiro.');
      return;
    }

    if (_isStarted) {
      _log(
          '🟡 [SessionRefreshService] Já está rodando (#$_startCount), ignorando start()');
      return;
    }

    _log('🟢 [SessionRefreshService] Iniciando monitoramento (primeira vez)');
    _validationTimer?.cancel();
    _lastAccessTimer?.cancel();

    _validationTimer =
        Timer.periodic(VALIDATION_INTERVAL, (_) => _validateSession());
    _lastAccessTimer =
        Timer.periodic(LAST_ACCESS_INTERVAL, (_) => _updateLastAccess());

    _isStarted = true;
    _startCount++;
    _log('✅ [SessionRefreshService] Timers configurados');
  }

  /// 🔥 STOP SEGURO
  void stop() {
    if (!_isStarted) {
      _log('🟡 [SessionRefreshService] Não estava rodando, ignorando stop()');
      return;
    }

    _log('🛑 [SessionRefreshService] Parando monitoramento');
    _validationTimer?.cancel();
    _lastAccessTimer?.cancel();
    _validationTimer = null;
    _lastAccessTimer = null;
    _isStarted = false;
  }

  /// 🔥 RESET COMPLETO (útil após logout)
  void reset() {
    _log('🔄 [SessionRefreshService] Resetando serviço');
    stop();
    _isValidating = false;
    _isLoggingOut = false;
  }

  /// 🔥 VERIFICA SE ESTÁ RODANDO
  bool get isRunning => _isStarted;

  bool get _isInitialized =>
      _sessionManager != null &&
      _validarSessaoUseCase != null &&
      _authController != null &&
      _authRepository != null;

  Future<void> _validateSession() async {
    if (_isValidating) {
      _log('⚠️ [SessionRefreshService] Validação já em andamento, ignorando');
      return;
    }

    if (_isLoggingOut) {
      _log(
          '⚠️ [SessionRefreshService] Logout em andamento, ignorando validação');
      return;
    }

    // Se está offline, NÃO invalida sessão
    if (!await _internetChecker.isOnline()) {
      _log('🌐 [SessionRefreshService] Offline, mantendo sessão local');
      return;
    }

    _isValidating = true;

    try {
      final sessionData = await _sessionManager.getFullSession();
      final user = await _sessionManager.getUser();

      if (sessionData == null || user == null) {
        _log(
            '⚠️ [SessionRefreshService] Sem sessão ativa, ignorando validação');
        return;
      }

      final token = sessionData['token'];
      final deviceId = sessionData['deviceId'];
      final cnpj = user.cnpj;
      final motorista = user.motorista;

      if (cnpj == null || motorista == null) {
        _log('⚠️ [SessionRefreshService] Dados de usuário incompletos');
        return;
      }

      _log('🔍 [SessionRefreshService] Validando sessão...');

      final result = await _validarSessaoUseCase.execute(
        cnpj,
        motorista,
        token: token,
        deviceId: deviceId,
      );

      result.fold(
        (failure) {
          if (failure is ConnectionFailure) {
            _log('🌐 [SessionRefreshService] Falha de rede, mantendo sessão');
          } else {
            _log(
                '❌ [SessionRefreshService] Erro na validação: ${failure.message}');
            _performLogout();
          }
        },
        (validationResult) {
          if (!validationResult.isValid) {
            _log(
                '⚠️ [SessionRefreshService] Sessão inválida - Motivo: ${validationResult.reason}');

            switch (validationResult.reason) {
              case SessionInvalidReason.replacedByAnotherDevice:
                _authController.setLastLogoutMessage(
                    'Sua sessão foi encerrada porque outro dispositivo acessou sua conta.');
                break;
              case SessionInvalidReason.licenseLimit:
                _authController.setLastLogoutMessage(
                    'Sessão encerrada: limite de usuários simultâneos atingido.');
                break;
              case SessionInvalidReason.expired:
                _authController.setLastLogoutMessage(
                    'Sua sessão expirou. Faça login novamente.');
                break;
              case SessionInvalidReason.revoked:
                _authController.setLastLogoutMessage(
                    'Sua sessão foi revogada. Contate o suporte.');
                break;
              default:
                _authController.setLastLogoutMessage(
                    'Sessão inválida. Faça login novamente.');
            }

            _performLogout();
          } else {
            _log('✅ [SessionRefreshService] Sessão válida');
          }
        },
      );
    } catch (e) {
      _log('❌ [SessionRefreshService] Erro na validação: $e');
    } finally {
      _isValidating = false;
    }
  }

  Future<void> _updateLastAccess() async {
    if (_isLoggingOut) return;

    if (!await _internetChecker.isOnline()) {
      _log(
          '🌐 [SessionRefreshService] Offline, ignorando atualização de acesso');
      return;
    }

    try {
      final user = await _sessionManager.getUser();
      if (user != null && user.cnpj != null && user.motorista != null) {
        await _authRepository.atualizarUltimoAcesso(
            user.cnpj!, user.motorista!);
        _log('🔄 [SessionRefreshService] Último acesso atualizado');
      }
    } catch (e) {
      _log('⚠️ [SessionRefreshService] Erro ao atualizar acesso: $e');
    }
  }

  Future<void> _performLogout() async {
    if (_isLoggingOut) {
      _log('⚠️ [SessionRefreshService] Logout já em andamento');
      return;
    }

    _isLoggingOut = true;
    _log('🚪 [SessionRefreshService] Executando logout automático');

    try {
      await _authController.onUnauthorized();
    } catch (e) {
      _log('❌ [SessionRefreshService] Erro no logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
