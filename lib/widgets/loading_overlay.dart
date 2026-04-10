import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  final String message;

  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message = "Carregando...",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
