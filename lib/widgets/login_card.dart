import 'package:flutter/material.dart';

class LoginCard extends StatelessWidget {
  final Widget child;

  const LoginCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}
