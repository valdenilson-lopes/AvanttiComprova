import 'package:flutter/material.dart';
import 'package:app/config/env.dart';

class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (Env.current == Environment.prod) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Env.current.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
