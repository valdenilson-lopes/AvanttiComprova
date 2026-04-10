import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/features/enterprise/domain/usecases/get_enterprises_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/get_current_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/save_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/select_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/remove_enterprise_usecase.dart';
import 'package:app/features/enterprise/domain/usecases/clear_all_enterprises_usecase.dart';
import 'package:app/features/enterprise/data/datasources/enterprise_local_datasource.dart';
import 'package:app/core/errors/failures.dart';
import 'dart:developer';

enum EnterpriseMode { select, manage }

class EnterpriseController {
  final GetEnterprisesUseCase _getEnterprisesUseCase;
  final GetCurrentEnterpriseUseCase _getCurrentEnterpriseUseCase;
  final SaveEnterpriseUseCase _saveEnterpriseUseCase;
  final SelectEnterpriseUseCase _selectEnterpriseUseCase;
  final RemoveEnterpriseUseCase _removeEnterpriseUseCase;
  final ClearAllEnterprisesUseCase _clearAllEnterprisesUseCase;
  final EnterpriseLocalDataSource _localDatasource;

  List<Enterprise> _enterprises = [];
  Enterprise? _currentEnterprise;
  String? _error;
  bool _isLoading = false;

  // Flag para evitar chamadas duplicadas
  bool _isLoadingEnterprises = false;

  // Contadores para rastreamento
  int _loadCount = 0;
  int _saveCount = 0;
  int _removeCount = 0;

  // Getters para a UI
  List<Enterprise> get enterprises => List.unmodifiable(_enterprises);
  Enterprise? get currentEnterprise => _currentEnterprise;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasEnterprises => _enterprises.isNotEmpty;

  // Callbacks
  Function()? onDataChanged;
  Function(String? error)? onError;
  Function(bool isLoading)? onLoadingChanged;

  EnterpriseController({
    required GetEnterprisesUseCase getEnterprisesUseCase,
    required GetCurrentEnterpriseUseCase getCurrentEnterpriseUseCase,
    required SaveEnterpriseUseCase saveEnterpriseUseCase,
    required SelectEnterpriseUseCase selectEnterpriseUseCase,
    required RemoveEnterpriseUseCase removeEnterpriseUseCase,
    required ClearAllEnterprisesUseCase clearAllEnterprisesUseCase,
    required EnterpriseLocalDataSource localDatasource, // 🔥 ADICIONADO
  })  : _getEnterprisesUseCase = getEnterprisesUseCase,
        _getCurrentEnterpriseUseCase = getCurrentEnterpriseUseCase,
        _saveEnterpriseUseCase = saveEnterpriseUseCase,
        _selectEnterpriseUseCase = selectEnterpriseUseCase,
        _removeEnterpriseUseCase = removeEnterpriseUseCase,
        _clearAllEnterprisesUseCase = clearAllEnterprisesUseCase,
        _localDatasource = localDatasource {
    print('🏗️  [EnterpriseController] Construtor chamado');
  }

  /// Carrega empresas do cache (offline-first)
  Future<void> loadFromCache() async {
    _loadCount++;
    print('═══════════════════════════════════════════════════════');
    print('📦 [EnterpriseController] loadFromCache #$_loadCount');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    _isLoading = true;
    onLoadingChanged?.call(true); // 🔥 Substituído notifyListeners

    try {
      final enterprises = await _localDatasource.getCachedEnterprises();
      final currentEnterprise = await _localDatasource.getCurrentEnterprise();

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      _enterprises = enterprises
          .map((e) => Enterprise(
                cnpj: e.cnpj,
                nomeFantasia: e.nomeFantasia,
                motorista: e.motorista,
                motoristaNome: e.motoristaNome,
              ))
          .toList();

      _currentEnterprise = currentEnterprise != null
          ? Enterprise(
              cnpj: currentEnterprise.cnpj,
              nomeFantasia: currentEnterprise.nomeFantasia,
              motorista: currentEnterprise.motorista,
              motoristaNome: currentEnterprise.motoristaNome,
            )
          : null;

      print('🟢 [EnterpriseController] loadFromCache SUCESSO - ${elapsed}ms');
      print('   - Empresas carregadas: ${_enterprises.length}');
      print(
          '   - Empresa atual: ${_currentEnterprise?.nomeFantasia ?? "nenhuma"}');

      _isLoading = false;
      onLoadingChanged?.call(false);
      onDataChanged?.call();
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [EnterpriseController] loadFromCache EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      _isLoading = false;
      onLoadingChanged?.call(false); // 🔥 Substituído notifyListeners
    }
  }

  Future<void> loadEnterprises() async {
    _loadCount++;
    print('═══════════════════════════════════════════════════════');
    print('📦 [EnterpriseController] loadEnterprises #$_loadCount');
    print('═══════════════════════════════════════════════════════');

    // Evita chamadas simultâneas
    if (_isLoadingEnterprises) {
      print('⚠️  [EnterpriseController] Já está carregando, ignorando chamada');
      print('═══════════════════════════════════════════════════════');
      return;
    }

    final startTime = DateTime.now();
    _isLoadingEnterprises = true;
    _setLoading(true);
    _clearError();

    try {
      print('🟡 [EnterpriseController] Executando GetEnterprisesUseCase...');
      final useCaseStart = DateTime.now();
      final result = await _getEnterprisesUseCase.execute();
      final useCaseTime =
          DateTime.now().difference(useCaseStart).inMilliseconds;
      print('✅ [EnterpriseController] UseCase respondido em ${useCaseTime}ms');

      result.fold(
        (failure) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print(
              '🔴 [EnterpriseController] loadEnterprises FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          print('   - Tipo: ${failure.runtimeType}');

          _error = _mapFailureToMessage(failure);
          onError?.call(_error);
          _setLoading(false);
        },
        (enterprises) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print(
              '🟢 [EnterpriseController] loadEnterprises SUCESSO - ${elapsed}ms');
          print('   - Empresas carregadas: ${enterprises.length}');

          if (enterprises.isNotEmpty) {
            print('   - Primeira empresa: ${enterprises.first.nomeFantasia}');
            if (enterprises.length > 1) {
              print('   - Última empresa: ${enterprises.last.nomeFantasia}');
            }
          }

          _enterprises = enterprises;
          _setLoading(false);
          onDataChanged?.call();

          // 👈 SE TEM EMPRESAS E NENHUMA SELECIONADA, SELECIONA A PRIMEIRA
          if (_enterprises.isNotEmpty && _currentEnterprise == null) {
            print(
                '🎯 [EnterpriseController] Nenhuma empresa atual, selecionando primeira: ${_enterprises.first.nomeFantasia}');
            selectEnterprise(_enterprises.first.cnpj);
          } else {
            _loadCurrentEnterprise();
          }
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [EnterpriseController] loadEnterprises EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      _setLoading(false);
    } finally {
      _isLoadingEnterprises = false;
      print('═══════════════════════════════════════════════════════');
    }
  }

  Future<void> _loadCurrentEnterprise() async {
    print('🟡 [EnterpriseController] _loadCurrentEnterprise iniciado');
    final startTime = DateTime.now();

    try {
      final result = await _getCurrentEnterpriseUseCase.execute();
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      result.fold(
        (failure) {
          print(
              '⚠️  [EnterpriseController] _loadCurrentEnterprise FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          _error = _mapFailureToMessage(failure);
          onError?.call(_error);

          // 👈 SE FALHOU AO CARREGAR EMPRESA ATUAL MAS TEM EMPRESAS, SELECIONA A PRIMEIRA
          if (_enterprises.isNotEmpty && _currentEnterprise == null) {
            print(
                '🎯 [EnterpriseController] Falha ao carregar empresa atual, selecionando primeira: ${_enterprises.first.nomeFantasia}');
            selectEnterprise(_enterprises.first.cnpj);
          }
        },
        (enterprise) {
          if (enterprise != null) {
            print(
                '🟢 [EnterpriseController] Empresa atual encontrada - ${elapsed}ms');
            print('   - Nome: ${enterprise.nomeFantasia}');
            print('   - CNPJ: ${enterprise.cnpj}');
            print('   - Motorista: ${enterprise.motorista ?? "Não definido"}');
            _currentEnterprise = enterprise;
          } else {
            print(
                '🟡 [EnterpriseController] Nenhuma empresa atual selecionada - ${elapsed}ms');
            _currentEnterprise = null;

            // 👈 SE NÃO TEM EMPRESA ATUAL MAS TEM EMPRESAS, SELECIONA A PRIMEIRA
            if (_enterprises.isNotEmpty) {
              print(
                  '🎯 [EnterpriseController] Nenhuma empresa atual, selecionando primeira: ${_enterprises.first.nomeFantasia}');
              selectEnterprise(_enterprises.first.cnpj);
            }
          }
          onDataChanged?.call();
        },
      );
    } catch (e, stack) {
      print('🔴 [EnterpriseController] _loadCurrentEnterprise EXCEÇÃO: $e');
      print(stack);

      // 👈 EM CASO DE EXCEÇÃO, TENTA SELECIONAR A PRIMEIRA EMPRESA
      if (_enterprises.isNotEmpty && _currentEnterprise == null) {
        print(
            '🎯 [EnterpriseController] Exceção ao carregar empresa atual, selecionando primeira: ${_enterprises.first.nomeFantasia}');
        selectEnterprise(_enterprises.first.cnpj);
      }
    }
  }

  Future<void> saveEnterprise(Enterprise enterprise) async {
    _saveCount++;
    print('═══════════════════════════════════════════════════════');
    print('💾 [EnterpriseController] saveEnterprise #$_saveCount');
    print('   - Empresa: ${enterprise.nomeFantasia}');
    print('   - CNPJ: ${enterprise.cnpj}');
    print('   - Motorista: ${enterprise.motorista ?? "Não definido"}');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    _setLoading(true);
    _clearError();

    try {
      final result = await _saveEnterpriseUseCase.execute(enterprise);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      result.fold(
        (failure) {
          print(
              '🔴 [EnterpriseController] saveEnterprise FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          _error = _mapFailureToMessage(failure);
          onError?.call(_error);
          _setLoading(false);
        },
        (_) {
          print(
              '🟢 [EnterpriseController] saveEnterprise SUCESSO - ${elapsed}ms');
          print('✅ Empresa salva com sucesso');
          // Recarrega a lista
          print('🟡 [EnterpriseController] Recarregando lista de empresas...');
          _setLoading(false);
          loadEnterprises();
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [EnterpriseController] saveEnterprise EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      _setLoading(false);
    }
    print('═══════════════════════════════════════════════════════');
  }

  Future<void> selectEnterprise(String cnpj) async {
    print('═══════════════════════════════════════════════════════');
    print('🎯 [EnterpriseController] selectEnterprise');
    print('   - CNPJ: $cnpj');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    _setLoading(true);
    _clearError();

    try {
      final result = await _selectEnterpriseUseCase.execute(cnpj);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      result.fold(
        (failure) {
          print(
              '🔴 [EnterpriseController] selectEnterprise FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          _error = _mapFailureToMessage(failure);
          onError?.call(_error);
          _setLoading(false);
        },
        (_) {
          print(
              '🟢 [EnterpriseController] selectEnterprise SUCESSO - ${elapsed}ms');
          print('✅ Empresa selecionada: $cnpj');
          _setLoading(false);
          _loadCurrentEnterprise(); // 👈 RECARREGA A EMPRESA ATUAL
          onDataChanged?.call();
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print(
          '🔴 [EnterpriseController] selectEnterprise EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      _setLoading(false);
    }
    print('═══════════════════════════════════════════════════════');
  }

  Future<void> removeEnterprise(String cnpj) async {
    _removeCount++;
    print('═══════════════════════════════════════════════════════');
    print('🗑️  [EnterpriseController] removeEnterprise #$_removeCount');
    print('   - CNPJ: $cnpj');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    _setLoading(true);
    _clearError();

    try {
      // Busca empresa antes de remover para log
      final empresaRemovida = _enterprises.firstWhere(
        (e) => e.cnpj == cnpj,
        orElse: () => Enterprise(cnpj: '', nomeFantasia: 'Desconhecida'),
      );

      print(
          '🟡 [EnterpriseController] Removendo empresa: ${empresaRemovida.nomeFantasia}');

      final result = await _removeEnterpriseUseCase.execute(cnpj);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      result.fold(
        (failure) {
          print(
              '🔴 [EnterpriseController] removeEnterprise FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          _error = _mapFailureToMessage(failure);
          onError?.call(_error);
          _setLoading(false);
        },
        (_) {
          print(
              '🟢 [EnterpriseController] removeEnterprise SUCESSO - ${elapsed}ms');
          print('✅ Empresa removida: ${empresaRemovida.nomeFantasia}');
          print('🟡 [EnterpriseController] Recarregando lista de empresas...');
          loadEnterprises(); // Recarrega a lista
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print(
          '🔴 [EnterpriseController] removeEnterprise EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      _setLoading(false);
    }
    print('═══════════════════════════════════════════════════════');
  }

  Future<void> clearAll() async {
    print('═══════════════════════════════════════════════════════');
    print('🔥 [EnterpriseController] clearAll - APAGANDO TODAS EMPRESAS');
    print('   - Empresas atuais: ${_enterprises.length}');
    print('═══════════════════════════════════════════════════════');

    final startTime = DateTime.now();
    _setLoading(true);
    _clearError();

    try {
      final result = await _clearAllEnterprisesUseCase.execute();
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      result.fold(
        (failure) {
          print('🔴 [EnterpriseController] clearAll FALHA - ${elapsed}ms');
          print('   - Erro: ${failure.message}');
          _error = _mapFailureToMessage(failure);
          onError?.call(_error);
          _setLoading(false);
        },
        (_) {
          print('🟢 [EnterpriseController] clearAll SUCESSO - ${elapsed}ms');
          print('✅ Todas as empresas foram removidas');
          _enterprises = [];
          _currentEnterprise = null;
          _setLoading(false);
          onDataChanged?.call();
        },
      );
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [EnterpriseController] clearAll EXCEÇÃO - ${elapsed}ms');
      print('🔴 Erro: $e');
      print('🔴 StackTrace:');
      print(stack);
      _setLoading(false);
    }
    print('═══════════════════════════════════════════════════════');
  }

  Enterprise? getEnterpriseByCnpj(String cnpj) {
    try {
      final empresa = _enterprises.firstWhere((e) => e.cnpj == cnpj);
      print(
          '🔍 [EnterpriseController] getEnterpriseByCnpj: $cnpj - Encontrada: ${empresa.nomeFantasia}');
      return empresa;
    } catch (_) {
      print(
          '⚠️  [EnterpriseController] getEnterpriseByCnpj: $cnpj - Não encontrada');
      return null;
    }
  }

  bool isCurrentEnterprise(String cnpj) {
    final isCurrent = _currentEnterprise?.cnpj == cnpj;
    if (isCurrent) {
      print('✅ [EnterpriseController] Empresa atual: $cnpj');
    }
    return isCurrent;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    onLoadingChanged?.call(value);
    if (value) {
      print('⏳ [EnterpriseController] Loading: $value');
    } else {
      print('✅ [EnterpriseController] Loading concluído');
    }
  }

  void _clearError() {
    if (_error != null) {
      print('🟡 [EnterpriseController] Limpando erro anterior: $_error');
    }
    _error = null;
    onError?.call(null);
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is CacheFailure) {
      return 'Erro de cache: ${failure.message}';
    } else if (failure is ConnectionFailure) {
      return 'Sem conexão com a internet';
    } else {
      return 'Erro: ${failure.message}';
    }
  }
}
