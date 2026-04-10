import 'package:flutter/material.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';

class EnterpriseList extends StatelessWidget {
  final EnterpriseController controller;
  final EnterpriseMode mode;

  const EnterpriseList({
    super.key,
    required this.controller,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.enterprises.length,
      itemBuilder: (context, index) {
        final enterprise = controller.enterprises[index];
        final isAtiva = controller.isCurrentEnterprise(enterprise.cnpj);

        return _buildEnterpriseCard(context, enterprise, isAtiva);
      },
    );
  }

  Widget _buildEnterpriseCard(
    BuildContext context,
    Enterprise enterprise,
    bool isAtiva,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.business,
          color: isAtiva ? Colors.blue : Colors.grey,
        ),
        title: Text(
          enterprise.nomeFantasia,
          style: TextStyle(
            fontWeight: isAtiva ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(enterprise.cnpj),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAtiva)
              const Chip(
                label: Text("ATIVA"),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
            if (mode == EnterpriseMode.manage)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmRemove(context, enterprise),
              ),
          ],
        ),
        onTap: () => _selectEnterprise(context, enterprise),
      ),
    );
  }

  Future<void> _selectEnterprise(
    BuildContext context,
    Enterprise enterprise,
  ) async {
    await controller.selectEnterprise(enterprise.cnpj);

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    Enterprise enterprise,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover empresa"),
        content: Text("Deseja realmente remover ${enterprise.nomeFantasia}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("REMOVER"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.removeEnterprise(enterprise.cnpj);

      // Se removeu a empresa ativa e não há mais empresas, volta pro login
      if (!controller.hasEnterprises && context.mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }
}
