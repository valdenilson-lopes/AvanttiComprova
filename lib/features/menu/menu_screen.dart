import 'package:flutter/material.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/app/app_routes.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text("Empresas"),
            onTap: () {
              AppRoutes.pushToEnterprises(
                context,
                mode: EnterpriseMode.manage,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sair"),
            onTap: () {
              AppRoutes.popToLogin(context);
            },
          ),
        ],
      ),
    );
  }
}
