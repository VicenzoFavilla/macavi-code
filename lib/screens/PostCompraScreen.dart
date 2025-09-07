import 'package:flutter/material.dart';

class PostCompraScreen extends StatelessWidget {
  const PostCompraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 46, 17),
      body: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              scaleEnabled: false, // Si querés permitir zoom, ponelo en true
              child: Padding(
  padding: const EdgeInsets.only(top: 10), // 🔼 Ajustá este valor a gusto
  child: Image.asset(
    'assets/gracias.png',
    fit: BoxFit.contain,
  ),
),

            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/menu');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Volver al Menú',
                    style: TextStyle(
                      color: Color.fromARGB(255, 233, 73, 25),
                      fontSize: 16,
                      fontFamily: "Aktiv"
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
