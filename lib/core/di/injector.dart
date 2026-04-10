import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/features/auth/domain/usecases/validar_sessao_usecase.dart';
import 'package:app/features/auth/presentation/controllers/login_controller.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/config/env.dart';
import 'package:app/features/auth/data/datasources/fake_auth_remote_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_supabase_datasource.dart';
import 'package:app/features/enterprise/data/datasources/enterprise_local_datasource.dart';
import 'package:app/features/enterprise/data/repositories/enterprise_repository_impl.dart';
import 'package:app/features/enterprise/domain/repositories/enterprise_repository.dart';
import 'package:app/features/enterprise/domain/usecases/get_enterprises_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/get_current_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/save_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/select_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/remove_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/clear_all_enterprises_usecase.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:app/services/secure_storage_service.dart';
import 'package:app/services/session_manager.dart';
import 'package:app/services/session_refresh_service.dart';
import 'package:app/services/device_id_service.dart';

final getIt = GetIt.instance;

Future<void> setupInjector() async {
  final stopwatchGlobal = Stopwatch()..start();
  _log('═══════════════════════════════════════════════════════');
  _log('🚀 INICIANDO SETUP DO INJECTOR');
  _log('═══════════════════════════════════════════════════════');
  _log('Ambiente: ${Env.current.name.toUpperCase()}');
  _log('');

  // ==================== CORE ====================
  _log('📦 [CORE] Iniciando configuração...');

  var stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando SharedPreferences...');
  getIt.registerSingletonAsync<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );
  await getIt.isReady<SharedPreferences>();
  _log('  ✅ SharedPreferences registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando StorageService...');
  getIt.registerSingleton<IStorageService>(
    StorageServiceImpl(getIt<SharedPreferences>()),
  );
  _log('  ✅ StorageService registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [CORE] Configuração concluída - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // Secure Storage Service
  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando SecureStorageService...');
  getIt.registerSingleton<SecureStorageService>(SecureStorageService());
  _log(
      '  ✅ SecureStorageService registrado - ${stopwatch.elapsedMilliseconds}ms');

  // Session Manager
  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando SessionManager...');
  getIt.registerSingleton<SessionManager>(
    SessionManager(
      secureStorage: getIt<SecureStorageService>(),
      storage: getIt<IStorageService>(),
    ),
  );
  _log('  ✅ SessionManager registrado - ${stopwatch.elapsedMilliseconds}ms');

  // 🔥 DeviceId Service
  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando DeviceIdService...');
  getIt.registerSingleton<DeviceIdService>(
    DeviceIdService(getIt<SecureStorageService>()),
  );
  _log('  ✅ DeviceIdService registrado - ${stopwatch.elapsedMilliseconds}ms');
  _log('');

  // ==================== AUTH DATA SOURCES ====================
  _log('📦 [AUTH] Configurando Data Sources...');

  stopwatch = Stopwatch()..start();

  switch (Env.current) {
    case Environment.dev:
      _log('  ⏳ Registrando FakeAuthRemoteDataSource (modo DEV)...');
      getIt.registerSingleton<AuthRemoteDataSource>(
        FakeAuthRemoteDataSourceImpl(),
      );
      break;
    case Environment.homolog:
    case Environment.prod:
      _log(
          '  ⏳ Registrando AuthSupabaseDataSource (modo ${Env.current.name.toUpperCase()})...');
      getIt.registerSingleton<AuthRemoteDataSource>(
        AuthSupabaseDataSource(),
      );
      break;
  }
  _log(
      '  ✅ AuthRemoteDataSource registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando AuthLocalDataSource...');
  getIt.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(getIt<IStorageService>()),
  );
  _log(
      '  ✅ AuthLocalDataSource registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [AUTH] Data Sources configurados - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== AUTH REPOSITORY ====================
  _log('📦 [AUTH] Configurando Repository...');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando AuthRepository...');
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remote: getIt<AuthRemoteDataSource>(),
      local: getIt<AuthLocalDataSource>(),
    ),
  );
  _log('  ✅ AuthRepository registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [AUTH] Repository configurado - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== AUTH USECASES ====================
  _log('📦 [AUTH] Configurando UseCases...');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(() => LoginUseCase(getIt<AuthRepository>()));
  _log('  ✅ LoginUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(() => GetSessionUseCase(getIt<AuthRepository>()));
  _log('  ✅ GetSessionUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(() => LogoutUseCase(getIt<AuthRepository>()));
  _log('  ✅ LogoutUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(() => ValidarSessaoUseCase(getIt<AuthRepository>()));
  _log(
      '  ✅ ValidarSessaoUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [AUTH] UseCases configurados - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== AUTH CONTROLLER ====================
  _log('📦 [AUTH] Configurando AuthController...');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando AuthController...');
  getIt.registerSingleton<AuthController>(
    AuthController(getIt<LogoutUseCase>()),
  );
  _log('  ✅ AuthController registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [AUTH] AuthController configurado - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== SESSION REFRESH SERVICE ====================
  _log('📦 [SESSION] Configurando SessionRefreshService...');
  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando SessionRefreshService...');

  // Registra o Singleton usando a instância estática da classe
  getIt
      .registerSingleton<SessionRefreshService>(SessionRefreshService.instance);

  // 🔥 INICIALIZA O SERVICE COM AS DEPENDÊNCIAS
  getIt<SessionRefreshService>().init(
    sessionManager: getIt<SessionManager>(),
    validarSessaoUseCase: getIt<ValidarSessaoUseCase>(),
    authController: getIt<AuthController>(),
    authRepository: getIt<AuthRepository>(),
  );

  _log(
      '  ✅ SessionRefreshService registrado e inicializado - ${stopwatch.elapsedMilliseconds}ms');
  _log(
      '✅ [SESSION] SessionRefreshService configurado - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== ENTERPRISE DATA SOURCES ====================
  _log('📦 [ENTERPRISE] Configurando Data Sources...');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando EnterpriseLocalDataSource...');
  getIt.registerSingleton<EnterpriseLocalDataSource>(
    EnterpriseLocalDataSourceImpl(getIt<IStorageService>()),
  );
  _log(
      '  ✅ EnterpriseLocalDataSource registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [ENTERPRISE] Data Source configurado - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== ENTERPRISE REPOSITORY ====================
  _log('📦 [ENTERPRISE] Configurando Repository...');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando EnterpriseRepository...');
  getIt.registerSingleton<EnterpriseRepository>(
    EnterpriseRepositoryImpl(getIt<EnterpriseLocalDataSource>()),
  );
  _log(
      '  ✅ EnterpriseRepository registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [ENTERPRISE] Repository configurado - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== ENTERPRISE USECASES ====================
  _log('📦 [ENTERPRISE] Configurando UseCases...');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => GetEnterprisesUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ GetEnterprisesUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => GetCurrentEnterpriseUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ GetCurrentEnterpriseUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => SaveEnterpriseUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ SaveEnterpriseUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => SelectEnterpriseUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ SelectEnterpriseUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => RemoveEnterpriseUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ RemoveEnterpriseUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  getIt.registerFactory(
      () => ClearAllEnterprisesUseCase(getIt<EnterpriseRepository>()));
  _log(
      '  ✅ ClearAllEnterprisesUseCase registrado - ${stopwatch.elapsedMilliseconds}ms');

  _log(
      '✅ [ENTERPRISE] UseCases configurados - ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('');

  // ==================== CONTROLLERS ====================
  _log('📦 [CONTROLLERS] Configurando Controllers...');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando LoginController...');
  getIt.registerFactory(() => LoginController(
        loginUseCase: getIt<LoginUseCase>(),
        getSessionUseCase: getIt<GetSessionUseCase>(),
        saveEnterpriseUseCase: getIt<SaveEnterpriseUseCase>(),
      ));
  _log('  ✅ LoginController registrado - ${stopwatch.elapsedMilliseconds}ms');

  stopwatch = Stopwatch()..start();
  _log('  ⏳ Registrando EnterpriseController...');
  getIt.registerFactory(() => EnterpriseController(
        getEnterprisesUseCase: getIt<GetEnterprisesUseCase>(),
        getCurrentEnterpriseUseCase: getIt<GetCurrentEnterpriseUseCase>(),
        saveEnterpriseUseCase: getIt<SaveEnterpriseUseCase>(),
        selectEnterpriseUseCase: getIt<SelectEnterpriseUseCase>(),
        removeEnterpriseUseCase: getIt<RemoveEnterpriseUseCase>(),
        clearAllEnterprisesUseCase: getIt<ClearAllEnterprisesUseCase>(),
        localDatasource: getIt<EnterpriseLocalDataSource>(),
      ));
  _log(
      '  ✅ EnterpriseController registrado - ${stopwatch.elapsedMilliseconds}ms');

  // ==================== FINALIZADO ====================
  _log('═══════════════════════════════════════════════════════');
  _log('✅ SETUP DO INJECTOR CONCLUÍDO!');
  _log('⏱️  Tempo total: ${stopwatchGlobal.elapsedMilliseconds}ms');
  _log('═══════════════════════════════════════════════════════');
}

void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}
