import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.content_cut, size: 80, color: AppColors.gold),
            const SizedBox(height: 16),
            const Text(
              "CORTE & ESTILO",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 48),

            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: "E-mail",
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: "Senha",
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              child: const Text("ENTRAR"),
            ),
          ],
        ),
      ),
    );
  }
}
