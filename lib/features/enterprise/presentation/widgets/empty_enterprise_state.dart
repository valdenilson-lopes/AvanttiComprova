import 'package:flutter/material.dart';

class EmptyEnterpriseState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const EmptyEnterpriseState({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma empresa cadastrada",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAddPressed,
            child: const Text("CADASTRAR EMPRESA"),
          ),
        ],
      ),
    );
  }
}
