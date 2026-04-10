import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterLinks extends StatelessWidget {
  const FooterLinks({super.key});

  Future<void> _abrirLink(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Erro ao abrir link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _abrirLink("https://www.avantti.com"),
          child: Image.asset("assets/images/logo.png", height: 70),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: "Informações",
              onPressed: () => _abrirLink("https://www.avantti.com/info"),
              icon: const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 28,
              ),
            ),
            IconButton(
              tooltip: "Email",
              onPressed: () => _abrirLink("mailto:mcorinthians2009@gmail.com"),
              icon: const Icon(
                Icons.email_outlined,
                color: Colors.orange,
                size: 28,
              ),
            ),
            IconButton(
              tooltip: "Site",
              onPressed: () => _abrirLink("https://www.avantti.com"),
              icon: const Icon(Icons.language, color: Colors.orange, size: 28),
            ),
            IconButton(
              tooltip: "Instagram",
              onPressed: () =>
                  _abrirLink("https://instagram.com/sandersonfsilv"),
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.orange,
                size: 28,
              ),
            ),
            IconButton(
              tooltip: "WhatsApp",
              onPressed: () => _abrirLink(
                "https://wa.me/5584992108453?text=Olá,%20estou%20usando%20o%20Avantti%20Comprova%20e%20preciso%20de%20suporte.",
              ),
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.orange,
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
