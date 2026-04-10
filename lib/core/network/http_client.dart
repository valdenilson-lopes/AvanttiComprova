import 'package:dio/dio.dart';
import 'package:app/config/env.dart';
import 'package:app/core/constants/api_constants.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/services/session_manager.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/core/errors/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class HttpClient {
  late final Dio _dio;
  late final SessionManager _sessionManager;
  late final IStorageService _storage;

  // Controle para evitar loop de logout
  bool _isLoggingOut = false;

  HttpClient() {
    _sessionManager = getIt<SessionManager>();
    _storage = getIt<IStorageService>();

    final baseUrl = _getBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      print('🌐 REQUEST: ${options.method} ${options.path}');
      if (options.data != null) {
        print('📦 DATA: ${options.data}');
      }
    }

    try {
      final token = await _sessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('🔑 Token adicionado ao header');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Não foi possível adicionar token: $e');
      }
    }

    return handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      print(
        '✅ RESPONSE: ${response.statusCode} - ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      print('❌ ERROR: ${error.message}');
      if (error.response != null) {
        print('   Status: ${error.response?.statusCode}');
        print('   Data: ${error.response?.data}');
      }
    }

    // Tratamento de erro de conexão
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      throw ConnectionFailure('Sem conexão com a internet');
    }

    // Tratamento global 401 com proteção contra loop
    if (error.response?.statusCode == 401 && !_isLoggingOut) {
      _isLoggingOut = true;

      if (kDebugMode) {
        print('🔐 Token inválido ou expirado - Disparando logout automático');
      }

      await _handleUnauthorized();

      // Reset após logout completo
      _isLoggingOut = false;
    }

    return handler.next(error);
  }

  Future<void> _handleUnauthorized() async {
    try {
      if (!getIt.isRegistered<AuthController>()) {
        if (kDebugMode) {
          print('⚠️ AuthController não registrado ainda');
        }
        return;
      }

      final authController = getIt<AuthController>();

      if (!getIt.isRegistered<GlobalKey<NavigatorState>>()) {
        if (kDebugMode) {
          print('⚠️ navigatorKey não registrado ainda');
        }
        return;
      }

      final navigatorKey = getIt<GlobalKey<NavigatorState>>();

      // 🔥 TENTA AGUARDAR O NAVIGATOR FICAR DISPONÍVEL
      if (navigatorKey.currentState == null) {
        if (kDebugMode) {
          print('⚠️ NavigatorState nulo, aguardando 500ms...');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Verifica novamente após o delay
      if (navigatorKey.currentState != null) {
        await authController.onUnauthorized();
      } else {
        if (kDebugMode) {
          print('⚠️ NavigatorState ainda nulo, usando forceLogout');
        }
        await authController.forceLogout();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao processar logout automático: $e');
      }
    }
  }

  String _getBaseUrl() {
    switch (Env.current) {
      case Environment.dev:
        return ApiConstants.baseUrlDev;
      case Environment.homolog:
        return ApiConstants.baseUrlHomolog;
      case Environment.prod:
        return ApiConstants.baseUrlProd;
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) {
    return _dio.get(path, queryParameters: queryParams, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParams,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParams,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParams,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) {
    return _dio.delete(path, queryParameters: queryParams, options: options);
  }
}
