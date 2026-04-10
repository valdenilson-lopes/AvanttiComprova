import 'package:flutter/material.dart';
import 'package:app/core/dev/dev_menu.dart';

class LoginLogo extends StatefulWidget {
  const LoginLogo({super.key});

  @override
  State<LoginLogo> createState() => _LoginLogoState();
}

class _LoginLogoState extends State<LoginLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;

  int devTapCount = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _logoController,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _logoController,
          curve: Curves.easeOutBack,
        ),
        child: GestureDetector(
          onTap: () {
            devTapCount++;

            if (devTapCount >= 5) {
              devTapCount = 0;
              DevMenu.abrir(context);
            }
          },
          child: Column(
            children: [
              Image.asset("assets/images/icon.png", height: 90),
              const SizedBox(height: 12),
              const Text(
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
