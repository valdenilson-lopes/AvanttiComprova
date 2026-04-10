import 'package:flutter/material.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/features/enterprise/presentation/widgets/company_header.dart';
import 'package:app/app/app_routes.dart';
import 'package:app/services/session_refresh_service.dart';
import 'package:app/config/env.dart';
import 'package:app/core/utils/internet_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeMessage;

  const HomeScreen({super.key, this.showWelcomeMessage = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GetSessionUseCase _getSessionUseCase = getIt<GetSessionUseCase>();
  final EnterpriseController _enterpriseController =
      getIt<EnterpriseController>();
  final InternetChecker _internetChecker = InternetChecker();

  // Referência para o serviço de sessão
  late final SessionRefreshService _sessionRefreshService;

  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    print('🏠 [HOME] initState iniciado');

    // 🔥 USA O SINGLETON - NÃO CRIA NOVA INSTÂNCIA
    _sessionRefreshService = SessionRefreshService.instance;

    // Adiciona observer para lifecycle do app
    WidgetsBinding.instance.addObserver(this);

    _enterpriseController.onDataChanged = () {
      if (mounted) setState(() {});
    };

    _checkConnectivity();
    _listenConnectivity();
    _loadData();

    // 🔥 Inicia monitoramento de sessão (SEGURAMENTE)
    _sessionRefreshService.start();

    // Mostra mensagem de boas-vindas se necessário
    if (widget.showWelcomeMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bem-vindo! Login realizado com sucesso.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }

    print('🏠 [HOME] initState concluído');
  }

  @override
  void dispose() {
    print('🏠 [HOME] dispose - Parando monitoramento');

    // 🔥 PARA O MONITORAMENTO AO SAIR DA TELA
    _sessionRefreshService.stop();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('🔄 [HOME] App retornou para foreground');
        _checkConnectivity();
        break;
      case AppLifecycleState.paused:
        print('⏸️ [HOME] App foi para background');
        break;
      default:
        break;
    }
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _internetChecker.isOnline();
    if (mounted) {
      setState(() => _isOffline = !isOnline);
    }
  }

  void _listenConnectivity() {
    _internetChecker.onConnectivityChange.listen((result) {
      if (mounted) {
        setState(() => _isOffline = result == ConnectivityResult.none);
      }
    });
  }

  void _onFeatureThatNeedsInternet(String featureName) async {
    final isOnline = await _internetChecker.isOnline();
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta funcionalidade precisa de internet.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    // Executa ação online
    print('👆 [HOME] Acessando $featureName (online)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo $featureName...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Método para trocar conta (não apaga dados)
  void _trocarConta() {
    print('🔄 [HOME] Trocar conta - Navegando para login');

    // 🔥 Para o monitoramento antes de sair
    _sessionRefreshService.stop();

    // Usa pushReplacementNamed para evitar loop
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadData() async {
    print('📥 [HOME] Carregando dados do usuário');
    final startTime = DateTime.now();

    final userResult = await _getSessionUseCase.execute();

    if (!mounted) return;

    userResult.fold(
      (failure) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        print(
            '❌ [HOME] Falha ao carregar usuário - ${elapsed}ms: ${failure.message}');
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
      (user) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        print(
            '✅ [HOME] Usuário carregado em ${elapsed}ms: ${user?.nome ?? "null"}');
        print('   - CNPJ: ${user?.cnpj ?? "null"}');
        print('   - Motorista: ${user?.motorista ?? "null"}');

        setState(() {
          _user = user;
          _isLoading = false;
        });

        if (user == null) {
          print('⚠️ [HOME] Usuário nulo, redirecionando para login');
          // 🔥 Para o monitoramento caso a sessão seja nula
          _sessionRefreshService.stop();
          AppRoutes.popToLogin(context);
        } else {
          // Carrega empresas do cache (offline-first)
          _enterpriseController.loadFromCache();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _trocarConta,
                child: const Text('Voltar ao login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não encontrado')),
      );
    }

    final empresaAtual = _enterpriseController.currentEnterprise;

    return Scaffold(
      appBar: AppBar(
        title: empresaAtual != null
            ? CompanyHeader(
                empresa: empresaAtual,
                onTap: () {
                  AppRoutes.pushToEnterprises(
                    context,
                    mode: EnterpriseMode.select,
                  );
                },
              )
            : const Text("Avantti Comprova"),
        actions: [
          // Indicador de offline
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          // Botão para trocar conta (não apaga dados)
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _trocarConta,
            tooltip: "Trocar conta",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.person, size: 30, color: Colors.blue),
                title: Text(
                  'Bem-vindo, ${_user!.nome}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${_user!.id}'),
                    if (_user!.motorista != null)
                      Text('Motorista: ${_user!.motorista}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Indicador de monitoramento (apenas para debug)
            if (Env.current != Environment.prod)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Monitoramento de sessão ativo',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: [
                  _menuButton(
                    Icons.inventory,
                    "Estoque",
                    () => _onFeatureThatNeedsInternet('Estoque'),
                  ),
                  _menuButton(
                    Icons.description,
                    "Documentos",
                    () => _onFeatureThatNeedsInternet('Documentos'),
                  ),
                  _menuButton(
                    Icons.camera_alt,
                    "Câmera",
                    () => _onFeatureThatNeedsInternet('Câmera'),
                  ),
                  _menuButton(
                    Icons.history,
                    "Histórico",
                    () => _onFeatureThatNeedsInternet('Histórico'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(IconData icon, String titulo, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
