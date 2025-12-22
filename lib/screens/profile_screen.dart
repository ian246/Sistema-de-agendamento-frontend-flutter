import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingEmail = false;
  final TextEditingController _emailController = TextEditingController(
    text: "ian@flutter.dev",
  );

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meu Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.cardDark,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppColors.charcoal,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Abrir galeria/câmera..."),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email",
                style: TextStyle(color: AppColors.gold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              readOnly: !_isEditingEmail,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isEditingEmail ? Icons.check : Icons.edit,
                    color: _isEditingEmail ? AppColors.green : AppColors.gold,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditingEmail = !_isEditingEmail;
                    });
                    if (!_isEditingEmail) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email atualizado!")),
                      );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  "SAIR DA CONTA",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
