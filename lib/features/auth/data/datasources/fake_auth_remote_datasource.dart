import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app/features/enterprise/data/models/enterprise_model.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/models/license_model.dart';
import 'package:app/features/auth/data/models/session_validation_result.dart';
import 'dart:math';
import 'dart:async';

class FakeAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // 🔥 CONTROLE DE MODO OFFLINE
  bool _offlineMode = false;
  void setOfflineMode(bool value) => _offlineMode = value;

  // Empresas cadastradas
  static const Map<String, EnterpriseModel> _empresasFake = {
    "10695880000111": EnterpriseModel(
      cnpj: "10695880000111",
      nomeFantasia: "Manuel Auto Peças",
    ),
    "10818068000136": EnterpriseModel(
      cnpj: "10818068000136",
      nomeFantasia: "Belt Sistemas",
    ),
    "55569441000109": EnterpriseModel(
      cnpj: "55569441000109",
      nomeFantasia: "Auto Peças Center",
    ),
    "08826349000199": EnterpriseModel(
      cnpj: "08826349000199",
      nomeFantasia: "Metal Louca",
    ),
  };

  // Motoristas por empresa
  final Map<String, List<String>> _motoristasFake = {
    '10695880000111': ['1'],
    '10818068000136': ['2'],
    '55569441000109': ['3'],
    '08826349000199': ['4', '5', '6', '7'],
  };

  // LICENÇAS POR EMPRESA
  final Map<String, Map<String, dynamic>> _licencasFake = {
    "10695880000111": {
      "limite": 2,
      "expiraEm": DateTime(2026, 12, 31, 23, 59, 59),
      "ativa": true,
      "timeoutInatividade": const Duration(minutes: 30),
    },
    "10818068000136": {
      "limite": 1,
      "expiraEm": DateTime(2025, 1, 1, 0, 0, 0),
      "ativa": false,
      "timeoutInatividade": const Duration(minutes: 30),
    },
    "55569441000109": {
      "limite": 3,
      "expiraEm": DateTime(2026, 12, 31, 23, 59, 59),
      "ativa": true,
      "timeoutInatividade": const Duration(minutes: 30),
    },
    "08826349000199": {
      "limite": 5,
      "expiraEm": DateTime(2026, 12, 31, 23, 59, 59),
      "ativa": true,
      "timeoutInatividade": const Duration(minutes: 30),
    },
  };

  // 🔥 SESSÕES ATIVAS COM DEVICE_ID
  // Estrutura: cnpj -> motorista -> dados da sessão
  final Map<String, Map<String, Map<String, dynamic>>> _sessoesAtivas = {};

  int _loginCount = 0;
  int _logoutCount = 0;
  int _validarSessaoCount = 0;
  int _atualizarAcessoCount = 0;

  Timer? _cleanupTimer;

  FakeAuthRemoteDataSourceImpl() {
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      limparSessoesExpiradas();
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  Future<void> limparSessoesExpiradas() async {
    print('🧹 [FAKE_DS] Limpando sessões expiradas por timeout');
    int removidas = 0;

    _sessoesAtivas.forEach((cnpj, motoristas) {
      final agora = DateTime.now();

      motoristas.forEach((motorista, sessao) {
        final ativa = sessao["ativo"] as bool;
        if (ativa) {
          final ultimoAcesso = DateTime.parse(sessao["ultimoAcesso"] as String);
          final timeoutSegundos = sessao["timeoutInatividade"] as int;
          final timeout = Duration(seconds: timeoutSegundos);
          final tempoInativo = agora.difference(ultimoAcesso);

          if (tempoInativo > timeout) {
            sessao["ativo"] = false;
            sessao["dataEncerramento"] = agora.toIso8601String();
            sessao["motivoEncerramento"] = "Timeout de inatividade automático";
            removidas++;
          }
        }
      });
    });

    if (removidas > 0) {
      print('✅ [FAKE_DS] $removidas sessões expiradas foram removidas');
    }
  }

  @override
  Future<Either<Failure, UserModel>> login(
    String cnpj,
    String motorista,
    String deviceId,
  ) async {
    _loginCount++;

    if (_offlineMode) {
      print('🌐 [FAKE_DS] Simulando erro de conexão (OFFLINE)');
      return Left(ConnectionFailure('Sem conexão com o servidor'));
    }

    final startTime = DateTime.now();

    print('═══════════════════════════════════════════════════════');
    print('🔐 [FAKE_DS] LOGIN UNIFICADO #$_loginCount');
    print('   - CNPJ: $cnpj');
    print('   - Motorista: $motorista');
    print('   - DeviceId: $deviceId');
    print('═══════════════════════════════════════════════════════');

    await Future.delayed(const Duration(milliseconds: 500));

    // 1. VERIFICA EMPRESA
    final empresa = _empresasFake[cnpj];
    if (empresa == null) {
      print('❌ [FAKE_DS] Empresa não encontrada');
      return Left(NotFoundFailure('Empresa não encontrada'));
    }

    // 2. VERIFICA MOTORISTA
    final motoristas = _motoristasFake[cnpj];
    if (motoristas == null || !motoristas.contains(motorista)) {
      print('❌ [FAKE_DS] Motorista inválido');
      return Left(InvalidCredentialsFailure());
    }

    // 3. VERIFICA LICENÇA
    final licenca = _licencasFake[cnpj];
    if (licenca == null) {
      print('❌ [FAKE_DS] Licença não encontrada');
      return Left(NotFoundFailure('Licença não encontrada'));
    }

    final limite = licenca["limite"] as int;
    final expiraEm = licenca["expiraEm"] as DateTime;
    final licencaAtiva = licenca["ativa"] as bool;
    final timeoutInatividade = licenca["timeoutInatividade"] as Duration;

    if (!licencaAtiva) {
      print('❌ [FAKE_DS] Licença DESATIVADA');
      return Left(
          LicencaExpiradaFailure('Licença desativada. Contate o suporte.'));
    }

    if (DateTime.now().isAfter(expiraEm)) {
      print('❌ [FAKE_DS] Licença EXPIRADA');
      return Left(
          LicencaExpiradaFailure('Licença expirada em ${expiraEm.toLocal()}'));
    }

    // Inicializa estrutura da empresa se não existir
    _sessoesAtivas.putIfAbsent(cnpj, () => {});

    final token = _gerarToken(cnpj, motorista, deviceId);
    final agora = DateTime.now();

    // 🔥 REGRA DE MULTI-DEVICE
    final sessaoExistente = _sessoesAtivas[cnpj]![motorista];

    if (sessaoExistente != null) {
      final ativa = sessaoExistente["ativo"] as bool;
      final deviceIdExistente = sessaoExistente["deviceId"] as String;

      // Caso 1: Mesmo dispositivo - reativa sessão
      if (ativa && deviceIdExistente == deviceId) {
        print('🔄 [FAKE_DS] Reativando sessão existente (mesmo dispositivo)');
        sessaoExistente["ultimoAcesso"] = agora.toIso8601String();
        sessaoExistente["ativo"] = true;
        sessaoExistente["token"] = token;
        sessaoExistente["reativadoEm"] = agora.toIso8601String();

        final sessoesAtivasCount = _contarSessoesAtivas(cnpj);

        return Right(UserModel(
          id: deviceId,
          nome: empresa.nomeFantasia,
          motorista: motorista,
          cnpj: cnpj,
          token: token,
          deviceId: deviceId,
          license: LicenseModel(
            limite: limite,
            emUso: sessoesAtivasCount,
            expiraEm: expiraEm,
            valida: true,
          ),
        ));
      }

      // Caso 2: Dispositivo diferente - invalida sessão anterior
      if (ativa && deviceIdExistente != deviceId) {
        print('⚠️ [FAKE_DS] Motorista logando em OUTRO dispositivo!');
        print('   - DeviceId anterior: $deviceIdExistente');
        print('   - Novo DeviceId: $deviceId');
        print('   - Invalidando sessão anterior...');

        sessaoExistente["ativo"] = false;
        sessaoExistente["dataEncerramento"] = agora.toIso8601String();
        sessaoExistente["motivoEncerramento"] =
            "Sessão substituída por outro dispositivo (deviceId: ${deviceId.substring(0, 8)}...)";
        sessaoExistente["substituidoPor"] = deviceId;
      }
    }

    // Conta sessões ativas para verificar limite de licença
    final sessoesAtivasCount = _contarSessoesAtivas(cnpj);

    if (sessoesAtivasCount >= limite) {
      print(
          '❌ [FAKE_DS] Limite de licença atingido: $sessoesAtivasCount/$limite');
      return Left(LimiteUsuariosFailure(
          'Limite de $limite usuário(s) simultâneo(s) atingido. Aguarde alguém sair ou contate o suporte.'));
    }

    // Cria nova sessão
    _sessoesAtivas[cnpj]![motorista] = {
      "deviceId": deviceId,
      "token": token,
      "ativo": true,
      "dataLogin": agora.toIso8601String(),
      "ultimoAcesso": agora.toIso8601String(),
      "ip": "192.168.1.${Random().nextInt(255)}",
      "timeoutInatividade": timeoutInatividade.inSeconds,
    };

    final novasSessoesAtivas = _contarSessoesAtivas(cnpj);

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('✅ [FAKE_DS] Login realizado em ${elapsed}ms');
    print('   - Sessões ativas agora: $novasSessoesAtivas/$limite');

    return Right(UserModel(
      id: deviceId,
      nome: empresa.nomeFantasia,
      motorista: motorista,
      cnpj: cnpj,
      token: token,
      deviceId: deviceId,
      license: LicenseModel(
        limite: limite,
        emUso: novasSessoesAtivas,
        expiraEm: expiraEm,
        valida: true,
      ),
    ));
  }

  @override
  Future<Either<Failure, SessionValidationResult>> validarSessao(
    String cnpj,
    String motorista, {
    String? token,
    String? deviceId,
  }) async {
    _validarSessaoCount++;

    if (_offlineMode) return Left(ConnectionFailure('Sem conexão'));

    await Future.delayed(const Duration(milliseconds: 150));

    final empresaSessoes = _sessoesAtivas[cnpj];
    if (empresaSessoes == null) {
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    }

    final sessao = empresaSessoes[motorista];
    if (sessao == null) {
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    }

    final ativa = sessao["ativo"] as bool;
    if (!ativa) {
      final motivo = sessao["motivoEncerramento"] as String? ?? "";
      if (motivo.contains("substituído")) {
        return Right(SessionValidationResult.invalid(
            SessionInvalidReason.replacedByAnotherDevice));
      }
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    }

    // Verifica token
    final tokenValido = token == null || sessao["token"] == token;
    if (!tokenValido) {
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    }

    // Verifica deviceId (se fornecido)
    if (deviceId != null && sessao["deviceId"] != deviceId) {
      print(
          '⚠️ [FAKE_DS] DeviceId mismatch! Esperado: ${sessao["deviceId"]}, Recebido: $deviceId');
      return Right(SessionValidationResult.invalid(
          SessionInvalidReason.replacedByAnotherDevice));
    }

    // Verifica timeout de inatividade
    final ultimoAcesso = DateTime.parse(sessao["ultimoAcesso"] as String);
    final timeoutSegundos = sessao["timeoutInatividade"] as int;
    final timeout = Duration(seconds: timeoutSegundos);
    final agora = DateTime.now();
    final tempoInativo = agora.difference(ultimoAcesso);

    if (tempoInativo > timeout) {
      sessao["ativo"] = false;
      sessao["dataEncerramento"] = agora.toIso8601String();
      sessao["motivoEncerramento"] = "Timeout de inatividade";
      return Right(
          SessionValidationResult.invalid(SessionInvalidReason.expired));
    }

    // Atualiza último acesso
    sessao["ultimoAcesso"] = agora.toIso8601String();

    return Right(SessionValidationResult.valid());
  }

  @override
  Future<Either<Failure, void>> logout(String cnpj, String motorista) async {
    _logoutCount++;

    if (_offlineMode) return Left(ConnectionFailure('Sem conexão'));

    await Future.delayed(const Duration(milliseconds: 200));

    final empresaSessoes = _sessoesAtivas[cnpj];
    if (empresaSessoes != null) {
      empresaSessoes.remove(motorista);
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> atualizarUltimoAcesso(
    String cnpj,
    String motorista,
  ) async {
    _atualizarAcessoCount++;

    if (_offlineMode) return Left(ConnectionFailure('Sem conexão'));

    final empresaSessoes = _sessoesAtivas[cnpj];
    if (empresaSessoes == null) return const Right(null);

    final sessao = empresaSessoes[motorista];
    if (sessao != null && sessao["ativo"] == true) {
      sessao["ultimoAcesso"] = DateTime.now().toIso8601String();
    }

    return const Right(null);
  }

  int _contarSessoesAtivas(String cnpj) {
    final empresaSessoes = _sessoesAtivas[cnpj];
    if (empresaSessoes == null) return 0;

    return empresaSessoes.values.where((s) => s["ativo"] == true).length;
  }

  String _gerarToken(String cnpj, String motorista, String deviceId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash =
        (cnpj.hashCode + motorista.hashCode + deviceId.hashCode + timestamp)
            .abs();
    return 'token_${hash.toRadixString(16)}_${timestamp.toRadixString(16)}';
  }
}
