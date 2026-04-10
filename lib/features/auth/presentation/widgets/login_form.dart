import 'package:flutter/material.dart';
import 'package:app/features/auth/presentation/controllers/login_controller.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/core/utils/cnpj_validator.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:app/widgets/loading_overlay.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/app/app_routes.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';

final cnpjMask = MaskTextInputFormatter(
  mask: '##.###.###/####-##',
  filter: {"#": RegExp(r'[0-9]')},
);

class LoginFormNew extends StatefulWidget {
  final String? initialCnpj;
  final bool autoFocus;

  const LoginFormNew({super.key, this.initialCnpj, this.autoFocus = false});

  @override
  State<LoginFormNew> createState() => _LoginFormNewState();
}

class _LoginFormNewState extends State<LoginFormNew> {
  late final LoginController _controller = getIt<LoginController>();
  late final EnterpriseController _enterpriseController =
      getIt<EnterpriseController>();

  final _cnpjController = TextEditingController();
  final _motoristaController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  Enterprise? _selectedEnterprise;
  bool _hasEnterprises = false;
  bool _showNewEnterpriseForm = false;
  bool _isLoadingEnterprises = false;
  String _motoristaNome = '';

  @override
  void initState() {
    super.initState();

    _controller.onLoadingChanged = (loading) {
      if (mounted) setState(() => _isLoading = loading);
    };

    _controller.onError = (error) {
      if (mounted) setState(() => _error = error);
    };

    _controller.onLoginSuccess = () async {
      print('✅ [LoginForm] Login bem-sucedido');

      if (mounted) {
        // Aguarda um pouco para o cache ser salvo
        await Future.delayed(const Duration(milliseconds: 300));

        // Recarrega as empresas
        await _loadEnterprises();

        // 🔥 CORREÇÃO: Pegar a empresa que acabou de ser cadastrada (pelo CNPJ do login)
        // Ao invés de pegar a primeira da lista
        if (_enterpriseController.enterprises.isNotEmpty) {
          // Pega o CNPJ que foi usado no login (está no _cnpjController)
          final cnpjLogado = CnpjValidator.limpar(_cnpjController.text);

          // Busca a empresa com esse CNPJ
          final empresaLogada = _enterpriseController.enterprises.firstWhere(
            (e) => e.cnpj == cnpjLogado,
            orElse: () => _enterpriseController.enterprises.first, // fallback
          );

          print(
              '🎯 [LoginForm] Selecionando empresa: ${empresaLogada.nomeFantasia} (CNPJ: ${empresaLogada.cnpj})');

          await _enterpriseController.selectEnterprise(empresaLogada.cnpj);

          await Future.delayed(const Duration(milliseconds: 200));

          if (mounted) {
            setState(() {
              _selectedEnterprise = _enterpriseController.currentEnterprise;
              _hasEnterprises = true;
              _motoristaNome = _selectedEnterprise?.motoristaNome ?? '';
            });

            print(
                '✅ [LoginForm] Empresa selecionada: ${_selectedEnterprise?.nomeFantasia}');

            AppRoutes.pushToHome(context, showWelcomeMessage: true);
          }
        } else {
          print('⚠️ [LoginForm] Nenhuma empresa encontrada após login');
          setState(() {
            _showNewEnterpriseForm = true;
            _hasEnterprises = false;
          });
        }
      }
    };

    _enterpriseController.onDataChanged = () {
      if (mounted && !_isLoadingEnterprises) {
        setState(() {
          _hasEnterprises = _enterpriseController.hasEnterprises;
          _selectedEnterprise = _enterpriseController.currentEnterprise;
          _motoristaNome = _selectedEnterprise?.motoristaNome ?? '';
          print(
              '📊 [LoginForm] onDataChanged - Empresa selecionada: ${_selectedEnterprise?.nomeFantasia ?? "nenhuma"}');
        });
      }
    };

    _loadEnterprises();

    if (widget.initialCnpj != null && widget.initialCnpj!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cnpjController.text = _formatCnpj(widget.initialCnpj!);
        setState(() => _showNewEnterpriseForm = true);
      });
    }
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _motoristaController.dispose();
    super.dispose();
  }

  Future<void> _loadEnterprises() async {
    if (_isLoadingEnterprises) return;
    _isLoadingEnterprises = true;

    print('🔄 [LoginForm] Carregando empresas...');
    await _enterpriseController.loadEnterprises();

    if (mounted) {
      setState(() {
        _hasEnterprises = _enterpriseController.hasEnterprises;
        _selectedEnterprise = _enterpriseController.currentEnterprise;
        _motoristaNome = _selectedEnterprise?.motoristaNome ?? '';
        print('📊 [LoginForm] Empresas carregadas: $_hasEnterprises');
        print(
            '📊 [LoginForm] Empresa atual: ${_selectedEnterprise?.nomeFantasia ?? "nenhuma"}');

        // 👈 SE TEM EMPRESAS MAS NENHUMA SELECIONADA, SELECIONA A PRIMEIRA
        if (_hasEnterprises &&
            _selectedEnterprise == null &&
            _enterpriseController.enterprises.isNotEmpty) {
          final primeiraEmpresa = _enterpriseController.enterprises.first;
          print(
              '🎯 [LoginForm] Nenhuma empresa selecionada, selecionando: ${primeiraEmpresa.nomeFantasia}');
          _enterpriseController.selectEnterprise(primeiraEmpresa.cnpj);
        }
      });
    }
    _isLoadingEnterprises = false;
  }

  String _formatCnpj(String cnpj) {
    final limpo = CnpjValidator.limpar(cnpj);
    if (limpo.length == 14) {
      return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12, 14)}';
    }
    return cnpj;
  }

  Future<void> _handleLogin() async {
    final cnpj = CnpjValidator.limpar(_cnpjController.text);
    final motorista = _motoristaController.text.trim();

    if (!CnpjValidator.isValid(cnpj)) {
      setState(() => _error = "CNPJ inválido");
      return;
    }

    if (motorista.isEmpty) {
      setState(() => _error = "Informe o motorista");
      return;
    }

    await _controller.login(cnpj, motorista);
  }

  Future<void> _handleSelectEnterprise(Enterprise enterprise) async {
    print('🎯 [LoginForm] Selecionando empresa: ${enterprise.nomeFantasia}');
    print('═══════════════════════════════════════════════════════');

    setState(() {
      _selectedEnterprise = enterprise;
      _motoristaNome = enterprise.motoristaNome ?? '';
      _isLoading = true;
      _error = null; // Limpa erro anterior
    });

    await _enterpriseController.selectEnterprise(enterprise.cnpj);

    // 🔥 AGUARDA UM POUCO PARA O ESTADO ATUALIZAR
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isLoading = false);

      // 🔥 VERIFICA SE A EMPRESA FOI REALMENTE SELECIONADA
      final currentCnpj = _enterpriseController.currentEnterprise?.cnpj;

      if (currentCnpj == enterprise.cnpj) {
        print('✅ [LoginForm] Empresa selecionada com sucesso');
        AppRoutes.pushToHome(context);
      } else {
        print('❌ [LoginForm] Falha ao selecionar empresa');
        print('   - Esperado: ${enterprise.cnpj}');
        print('   - Atual: $currentCnpj');
        setState(() {
          _error = 'Erro ao selecionar empresa. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _isLoading,
      message: "Processando...",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caso 1: Tem empresas cadastradas e não está no formulário de criação
          if (_hasEnterprises && !_showNewEnterpriseForm) ...[
            _buildEnterpriseInfo(),
            const SizedBox(height: 16),
            _buildEnterButton(),
            const SizedBox(height: 16),
            _buildAddNewButton(),
          ],

          // Caso 2: Formulário para nova empresa
          if (_showNewEnterpriseForm || !_hasEnterprises)
            _buildNewEnterpriseForm(),
        ],
      ),
    );
  }

  /// Card com os dados da empresa (estilo unificado)
  Widget _buildEnterpriseInfo() {
    // 🔥 Formata o CNPJ
    final cnpjFormatado = _formatarCnpj(_selectedEnterprise?.cnpj ?? '');

    final motoristaCodigo = _selectedEnterprise?.motorista ?? '';
    final motoristaNome = _motoristaNome;

    // 🔥 Texto do motorista formatado: "código - nome"
    final motoristaTexto = motoristaNome.isNotEmpty
        ? '$motoristaCodigo - $motoristaNome'
        : motoristaCodigo;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, size: 24, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<Enterprise>(
                    value: _selectedEnterprise,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    items: _enterpriseController.enterprises.map((enterprise) {
                      return DropdownMenuItem(
                        value: enterprise,
                        child: Text(enterprise.nomeFantasia),
                      );
                    }).toList(),
                    onChanged: (enterprise) {
                      if (enterprise != null) {
                        setState(() => _selectedEnterprise = enterprise);
                      }
                    },
                    icon: Icon(Icons.arrow_drop_down,
                        size: 28, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Linha 2: CNPJ formatado
            Row(
              children: [
                const SizedBox(width: 36),
                Icon(Icons.assignment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cnpjFormatado,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Linha 3: Motorista com código e nome
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 36),
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    motoristaTexto,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 Método para formatar CNPJ
  String _formatarCnpj(String cnpj) {
    final limpo = CnpjValidator.limpar(cnpj);
    if (limpo.length != 14) return cnpj;
    return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12, 14)}';
  }

  /// Botão ENTRAR (Estilo Card Branco)
  Widget _buildEnterButton() {
    // 👈 VERIFICAR SE PODE ENTRAR
    final canEnter = !_isLoading && _selectedEnterprise != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canEnter
            ? () => _handleSelectEnterprise(_selectedEnterprise!)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 0),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : const Text(
                "ENTRAR",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Link para alternar para o formulário de nova empresa
  Widget _buildAddNewButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            _showNewEnterpriseForm = true;
            _cnpjController.clear();
            _motoristaController.clear();
            _error = null;
          });
        },
        child: Text(
          "+ Nova empresa",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Formulário de Cadastro/Login
  Widget _buildNewEnterpriseForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasEnterprises)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                      onPressed: () => setState(() {
                        _showNewEnterpriseForm = false;
                        _error = null;
                      }),
                    ),
                    const Expanded(
                      child: Text(
                        "Nova empresa",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Equilibrar o ícone de volta
                  ],
                ),
              ),
            if (!_hasEnterprises)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  "Cadastre sua primeira empresa",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            TextField(
              controller: _cnpjController,
              inputFormatters: [cnpjMask],
              keyboardType: TextInputType.number,
              autofocus: widget.autoFocus,
              decoration: InputDecoration(
                labelText: "CNPJ",
                hintText: "00.000.000/0000-00",
                errorText:
                    _error != null && _error!.contains("CNPJ") ? _error : null,
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _motoristaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Código do motorista",
                hintText: "Ex: 123456",
                errorText:
                    _error != null && !_error!.contains("CNPJ") ? _error : null,
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _hasEnterprises ? "CADASTRAR" : "CADASTRAR E ENTRAR",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
