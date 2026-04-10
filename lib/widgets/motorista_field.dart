import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MotoristaField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const MotoristaField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: "Código do motorista",
        hintText: "Ex: 123456",
        prefixIcon: const Icon(Icons.person),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
