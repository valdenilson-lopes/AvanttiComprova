import 'package:flutter/material.dart';
import 'package:app/app/app_theme.dart';
import 'package:app/widgets/login_logo.dart';
import 'package:app/widgets/footer_links.dart';
import 'package:app/widgets/environment_badge.dart';
import 'package:app/features/auth/presentation/widgets/login_form.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/core/di/injector.dart';

class LoginScreen extends StatefulWidget {
  final String? initialCnpj;
  final bool autoFocus;

  const LoginScreen({super.key, this.initialCnpj, this.autoFocus = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  final EnterpriseController _enterpriseController =
      getIt<EnterpriseController>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // REMOVIDA a verificação automática de sessão
    // Agora o usuário sempre vê a tela de login
    // _verificarSessao(); // ❌ REMOVIDO
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // MÉTODO REMOVIDO - Não faz mais verificação automática
  // Future<void> _verificarSessao() async {
  //   final temSessao = await _controller.verificarSessao();
  //   if (temSessao && mounted) {
  //     AppRoutes.pushToHome(context);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo gradiente
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: loginBackgroundGradient),
          ),

          // Badge de ambiente
          const Positioned(top: 40, right: 20, child: EnvironmentBadge()),

          // 👈 INDICADOR DE CARREGAMENTO DAS EMPRESAS
          // Mostra um loading enquanto as empresas estão sendo carregadas
          if (_enterpriseController.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando empresas...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Conteúdo principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoginLogo(),
                    const SizedBox(height: 24),
                    // Formulário de login
                    LoginFormNew(
                      initialCnpj: widget.initialCnpj,
                      autoFocus: widget.autoFocus,
                    ),
                    const SizedBox(height: 20),
                    const FooterLinks(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
