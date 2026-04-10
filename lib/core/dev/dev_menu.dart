import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 ADICIONAR PARA SystemNavigator
import 'package:app/core/di/injector.dart';
import 'package:app/config/env.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/enterprise/domain/usecases/clear_all_enterprises_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/services/log_service.dart';
import 'dart:async';
import 'dart:io'; // 🔥 ADICIONAR PARA exit()

class DevMenu {
  static bool simularOffline = false;

  static void abrir(BuildContext context) {
    final clearAllEnterprises = getIt<ClearAllEnterprisesUseCase>();
    final logoutUseCase = getIt<LogoutUseCase>();
    final storage = getIt<IStorageService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 600,
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    "DEV MENU",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const Divider(),

                // Ambiente atual
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text("Ambiente atual"),
                  subtitle: Text(Env.current.name.toUpperCase()),
                ),

                ListTile(
                  title: const Text("DEV"),
                  onTap: () => _changeEnvironment(
                      context, Environment.dev, Colors.green),
                ),
                ListTile(
                  title: const Text("HOMOLOG"),
                  onTap: () => _changeEnvironment(
                      context, Environment.homolog, Colors.orange),
                ),
                ListTile(
                  title: const Text("PROD"),
                  onTap: () =>
                      _changeEnvironment(context, Environment.prod, Colors.red),
                ),

                const Divider(),

                // Ações de cache
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text("Limpar empresas"),
                  onTap: () => _executeHeavyOperation(
                    context,
                    operation: () async {
                      await clearAllEnterprises.execute();
                      return "✅ Empresas removidas!";
                    },
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Reset login (logout)"),
                  onTap: () => _executeHeavyOperation(
                    context,
                    operation: () async {
                      await logoutUseCase.execute();
                      return "✅ Logout realizado!";
                    },
                    onSuccess: (context) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/login",
                        (route) => false,
                      );
                    },
                  ),
                ),

                const Divider(),

                // Botão nuclear
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    "🔥 APAGAR TUDO (NUCLEAR)",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("ATENÇÃO!"),
                        content: const Text(
                          "Isso vai apagar TODOS os dados do app.\n\n"
                          "Empresas, motoristas, configurações... TUDO!\n\n"
                          "Tem certeza?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCELAR"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text("APAGAR TUDO"),
                          ),
                        ],
                      ),
                    );

                    if (confirmar != true) return;

                    _executeHeavyOperation(
                      context,
                      operation: () async {
                        await storage.clear();
                        await logoutUseCase.execute();
                        return "✅ Todos os dados foram apagados!";
                      },
                      onSuccess: (context) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          "/login",
                          (route) => false,
                        );
                      },
                    );
                  },
                ),

                const Divider(),

                SwitchListTile(
                  value: simularOffline,
                  title: const Text("Simular offline"),
                  onChanged: (value) {
                    simularOffline = value;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? "Modo offline ativado"
                                : "Modo offline desativado",
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text("Logs da API"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _LogScreen()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text("Info do dispositivo"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Informações"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Flutter App"),
                            const Text("Versão 1.0.0"),
                            const SizedBox(height: 8),
                            Text("Ambiente: ${Env.current.name}"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔥 MÉTODO CORRIGIDO - REINICIA O APP AUTOMATICAMENTE
  static Future<void> _changeEnvironment(
    BuildContext context,
    Environment environment,
    Color color,
  ) async {
    // Salva o novo ambiente
    await Env.set(environment);

    if (context.mounted) {
      // Fecha o DevMenu
      Navigator.pop(context);

      // Mostra diálogo informando que vai reiniciar
      final shouldRestart = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 8),
              Text("Ambiente alterado para ${environment.name.toUpperCase()}"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "O aplicativo será reiniciado para aplicar as alterações.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Após reiniciar, o app usará o servidor de ${environment.name.toUpperCase()}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text("REINICIAR AGORA"),
            ),
          ],
        ),
      );

      if (shouldRestart == true && context.mounted) {
        // Mostra mensagem de reinicialização
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Reiniciando app em ambiente ${environment.name.toUpperCase()}..."),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );

        // Aguarda 1 segundo para mostrar a mensagem
        await Future.delayed(const Duration(milliseconds: 500));

        // 🔥 FORÇA O REINÍCIO DO APP
        // Método 1: Usa SystemNavigator (funciona em release)
        try {
          SystemNavigator.pop();
        } catch (e) {
          // Método 2: Fallback usando exit (funciona em debug)
          // ignore: deprecated_member_use
          exit(0);
        }
      }
    }
  }

  // Método genérico para executar operações pesadas
  static Future<void> _executeHeavyOperation(
    BuildContext context, {
    required Future<String> Function() operation,
    Function(BuildContext)? onSuccess,
  }) async {
    // Mostra loading antes da operação pesada
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Processando..."),
              ],
            ),
          ),
        ),
      ),
    );

    // Executa a operação em background usando Future.microtask
    await Future.microtask(() async {
      try {
        final mensagem = await operation();

        if (context.mounted) {
          // Fecha o dialog de loading
          Navigator.pop(context);

          // Fecha o menu
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Mostra mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Executa callback de sucesso se existir
          if (onSuccess != null && context.mounted) {
            onSuccess(context);
          }
        }
      } catch (e) {
        if (context.mounted) {
          // Fecha o dialog de loading
          Navigator.pop(context);

          // Mostra mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }
}

// ... resto do código _LogScreen permanece igual
class _LogScreen extends StatelessWidget {
  const _LogScreen();

  @override
  Widget build(BuildContext context) {
    final logs = LogService.getLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs da API"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              LogService.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Logs limpos"),
                    duration: Duration(seconds: 1),
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhum log registrado"),
                ],
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        logs[i],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
