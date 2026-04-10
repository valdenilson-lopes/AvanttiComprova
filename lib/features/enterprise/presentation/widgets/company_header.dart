import 'package:flutter/material.dart';
import 'package:app/features/enterprise/domain/entities/enterprise.dart';

class CompanyHeader extends StatelessWidget {
  final Enterprise empresa;
  final VoidCallback onTap;

  const CompanyHeader({super.key, required this.empresa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, size: 20),
              const SizedBox(width: 6),
              Text(
                empresa.nomeFantasia,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          Text("CNPJ: ${empresa.cnpj}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
