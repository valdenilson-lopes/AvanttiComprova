import 'package:flutter/material.dart';
import 'package:app/features/enterprise/presentation/controllers/enterprise_controller.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';
import 'package:app/core/di/injector.dart';
import 'package:app/app/app_routes.dart';

class EnterpriseRecentList extends StatefulWidget {
  final Function(Enterprise) onSelect;

  const EnterpriseRecentList({super.key, required this.onSelect});

  @override
  State<EnterpriseRecentList> createState() => _EnterpriseRecentListState();
}

class _EnterpriseRecentListState extends State<EnterpriseRecentList> {
  late final EnterpriseController _controller = getIt<EnterpriseController>();

  @override
  void initState() {
    super.initState();

    _controller.onDataChanged = () {
      if (mounted) setState(() {});
    };

    _controller.loadEnterprises();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.hasEnterprises) {
      return const SizedBox();
    }

    final recentes = _controller.enterprises.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Empresas recentes",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...recentes.map(
          (e) => ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: Text(
              e.nomeFantasia,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(e.cnpj),
            trailing: const Icon(Icons.arrow_forward, size: 16),
            onTap: () => widget.onSelect(e),
          ),
        ),
        if (_controller.enterprises.length > 3)
          TextButton(
            onPressed: () {
              AppRoutes.pushToEnterprises(
                context,
                mode: EnterpriseMode.select,
              );
            },
            child: const Text("Ver todas"),
          ),
      ],
    );
  }
}
