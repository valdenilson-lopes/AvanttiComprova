import 'package:flutter/material.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/features/enterprise/presentation/widgets/enterprise_list.dart';
import 'package:app/features/enterprise/presentation/widgets/empty_enterprise_state.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/app/app_routes.dart';
import 'dart:async';

class EnterprisePage extends StatefulWidget {
  final EnterpriseMode mode;

  const EnterprisePage({super.key, required this.mode});

  @override
  State<EnterprisePage> createState() => _EnterprisePageState();
}

class _EnterprisePageState extends State<EnterprisePage> {
  late final EnterpriseController _controller = getIt<EnterpriseController>();

  // Flag para evitar múltiplos carregamentos
  bool _isInitialized = false;

  // Flag para controlar se o controller já está configurado
  bool _isControllerConfigured = false;

  // Timer para debounce de possíveis rebuilds
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _configureController();
  }

  @override
  void dispose() {
    // Cancela timer se existir
    _debounceTimer?.cancel();

    // Remove callbacks para evitar memory leaks
    _controller.onDataChanged = null;
    _controller.onError = null;
    _controller.onLoadingChanged = null;

    super.dispose();
  }

  void _configureController() {
    // Evita configurar múltiplas vezes
    if (_isControllerConfigured) return;
    _isControllerConfigured = true;

    _controller.onDataChanged = () {
      if (mounted) {
        // Usa setState com microtask para evitar rebuilds desnecessários
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    };

    _controller.onError = (error) {
      if (error != null && mounted) {
        // Usa microtask para evitar chamar showSnackBar durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    };

    _controller.onLoadingChanged = (loading) {
      if (mounted) {
        // Usa microtask para evitar rebuilds durante o build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    };

    // Carrega empresas apenas uma vez
    _loadEnterprisesOnce();
  }

  Future<void> _loadEnterprisesOnce() async {
    // Evita múltiplos carregamentos
    if (_isInitialized) return;
    _isInitialized = true;

    // Pequeno delay para garantir que tudo está pronto
    await Future.delayed(Duration.zero);

    // Verifica se ainda está montado antes de carregar
    if (!mounted) return;

    await _controller.loadEnterprises();
  }

  String get _title {
    switch (widget.mode) {
      case EnterpriseMode.select:
        return 'Selecionar empresa';
      case EnterpriseMode.manage:
        return 'Empresas cadastradas';
    }
  }

  Future<void> _logout() async {
    // Evita múltiplos logout simultâneos
    if (_controller.isLoading) return;

    // Mostra confirmação antes de sair
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair"),
        content: const Text("Tem certeza que deseja sair?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      AppRoutes.popToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Sair",
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              AppRoutes.pushToLogin(context, autoFocus: true);
            },
            tooltip: "Nova empresa",
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Mostra loading apenas se estiver carregando pela primeira vez
    if (_controller.isLoading && !_controller.hasEnterprises) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Carregando empresas..."),
          ],
        ),
      );
    }

    // Se tem empresas, mostra lista
    if (_controller.hasEnterprises) {
      return RefreshIndicator(
        onRefresh: () async {
          // Recarrega as empresas manualmente
          await _controller.loadEnterprises();
        },
        child: EnterpriseList(
          controller: _controller,
          mode: widget.mode,
        ),
      );
    }

    // Estado vazio (sem empresas)
    return EmptyEnterpriseState(
      onAddPressed: () => AppRoutes.pushToLogin(context, autoFocus: true),
    );
  }
}
