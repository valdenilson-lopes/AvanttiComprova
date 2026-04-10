import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onTap;

  const AppLogo({super.key, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: const [
              Image(image: AssetImage("assets/images/icon.png"), height: 90),
              SizedBox(height: 12),
              Text(
                "Avantti Comprova",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
