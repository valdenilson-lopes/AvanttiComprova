import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/save_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/services/device_id_service.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/core/utils/internet_checker.dart';

class LoginController {
  final LoginUseCase _loginUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final SaveEnterpriseUseCase _saveEnterpriseUseCase;
  late final DeviceIdService _deviceIdService;
  final InternetChecker _internetChecker = InternetChecker();

  int _loginAttempts = 0;

  LoginController({
    required LoginUseCase loginUseCase,
    required GetSessionUseCase getSessionUseCase,
    required SaveEnterpriseUseCase saveEnterpriseUseCase,
  })  : _loginUseCase = loginUseCase,
        _getSessionUseCase = getSessionUseCase,
        _saveEnterpriseUseCase = saveEnterpriseUseCase {
    _deviceIdService = getIt<DeviceIdService>();
    print('🏗️  [LoginController] Construtor chamado');
  }

  // Callbacks para UI
  Function(bool isLoading)? onLoadingChanged;
  Function(String? error)? onError;
  Function()? onLoginSuccess;

  Future<bool> verificarSessao() async {
    print('🟡 [LoginController] verificarSessao iniciado');
    final startTime = DateTime.now();
    onLoadingChanged?.call(true);

    try {
      final result = await _getSessionUseCase.execute();
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final isSuccess = result.isRight();
      final hasUser = result.fold((failure) => false, (user) => user != null);

      print('🟢 [LoginController] verificarSessao concluído em ${elapsed}ms');
      print('   - Sucesso: $isSuccess');
      print('   - Usuário logado: $hasUser');

      onLoadingChanged?.call(false);
      return hasUser;
    } catch (e, stack) {
      print('🔴 [LoginController] verificarSessao ERRO: $e');
      print('🔴 StackTrace:');
      print(stack);
      onLoadingChanged?.call(false);
      return false;
    }
  }

  Future<void> login(String cnpj, String motorista) async {
    // Verifica internet para primeiro login
    final isOnline = await _internetChecker.isOnline();

    if (!isOnline) {
      onError?.call(
          'É necessário estar conectado à internet para realizar o primeiro acesso.');
      return;
    }

    _loginAttempts++;
    print('═══════════════════════════════════════════════════════');
    print('🔐 [LoginController] login #$_loginAttempts');
    print('   - CNPJ: $cnpj');
    print('   - Motorista: $motorista');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    onLoadingChanged?.call(true);
    onError?.call(null);

    try {
      // Obtém ou cria o DeviceId
      print('🟡 [LoginController] Obtendo DeviceId...');
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      print('✅ [LoginController] DeviceId: $deviceId');

      print('🟡 [LoginController] Executando loginUseCase...');
      final loginStart = DateTime.now();
      final result = await _loginUseCase.execute(cnpj, motorista, deviceId);
      final loginTime = DateTime.now().difference(loginStart).inMilliseconds;
      print('✅ [LoginController] loginUseCase respondido em ${loginTime}ms');

      result.fold(
        (failure) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print('🔴 [LoginController] LOGIN FALHOU - ${elapsed}ms');
          print('   - Falha: ${failure.message}');
          print('   - Tipo: ${failure.runtimeType}');

          onLoadingChanged?.call(false);

          // 🔥 Tratamento de erro aprimorado
          String errorMessage;
          if (failure is NotFoundFailure) {
            errorMessage = 'CNPJ não encontrado';
          } else if (failure is InvalidCredentialsFailure) {
            errorMessage = 'Motorista inválido';
          } else if (failure is LicencaExpiradaFailure) {
            errorMessage = failure.message;
          } else if (failure is LimiteUsuariosFailure) {
            errorMessage = failure.message;
          } else if (failure is ConnectionFailure) {
            errorMessage = 'Sem conexão com a internet. Verifique sua rede.';
          } else if (failure is ServerFailure) {
            errorMessage = 'Erro no servidor. Tente novamente mais tarde.';
          } else {
            errorMessage = _mapFailureToMessage(failure);
          }

          onError?.call(errorMessage);
        },
        (user) async {
          print('🟢 [LoginController] LOGIN SUCESSO');
          print('   - Usuário: ${user.nome}');
          print('   - ID: ${user.id}');
          print('   - Motorista: ${user.motorista}');

          print('🟡 [LoginController] Salvando empresa no cache...');
          final saveStart = DateTime.now();
          final enterpriseEntity = Enterprise(
            cnpj: cnpj,
            nomeFantasia: user.nomeEmpresa ?? user.nome,
            motorista: motorista,
            motoristaNome: user.nome,
          );

          final saveResult =
              await _saveEnterpriseUseCase.execute(enterpriseEntity);
          final saveTime = DateTime.now().difference(saveStart).inMilliseconds;

          saveResult.fold(
            (failure) {
              print(
                  '⚠️ [LoginController] Erro ao salvar empresa: ${failure.message}');
            },
            (_) {
              print('✅ [LoginController] Empresa salva em ${saveTime}ms');
            },
          );

          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print('✅ [LoginController] Login completo em ${elapsed}ms');

          onLoadingChanged?.call(false);

          await Future.delayed(const Duration(milliseconds: 200));

          print('🚀 [LoginController] Chamando onLoginSuccess callback');
          onLoginSuccess?.call();
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [LoginController] login EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      onLoadingChanged?.call(false);
      onError?.call('Erro inesperado ao fazer login');
    }
    print('═══════════════════════════════════════════════════════');
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Sem conexão com a internet';
    } else if (failure is ServerFailure) {
      return 'Erro no servidor. Tente novamente.';
    } else {
      return 'Erro inesperado: ${failure.message}';
    }
  }
}
