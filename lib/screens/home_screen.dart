import 'package:flutter/material.dart';
import 'package:front_flutter/screens/appointments_screen.dart';
import 'package:front_flutter/screens/login_screen.dart';
import 'package:front_flutter/screens/profile_screen.dart';
import '../theme.dart';
import '../mock_data.dart';
import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista local para podermos alterar o estado
  List<Barber> barbers = mockBarbers;

  // Função para navegar e esperar o resultado
  void _goToBooking(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(barber: barbers[index]),
      ),
    );

    // Se voltou com dados (booked = true), atualiza a tela
    if (result != null && result is Map && result['booked'] == true) {
      setState(() {
        barbers[index].isBooked = true;
        barbers[index].bookedTime = result['time'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Agendamento confirmado com ${barbers[index].name}!"),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolha seu Profissional")),
      drawer: const _CustomDrawer(), // Drawer extraído abaixo
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: barbers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final barber = barbers[index];

          // O Card Clicável
          return InkWell(
            onTap: () => _goToBooking(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                // BORDA VERDE SE ESTIVER AGENDADO
                border: barber.isBooked
                    ? Border.all(color: AppColors.green, width: 2)
                    : Border.all(color: Colors.transparent),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar Simples
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    child: Text(
                      barber.name[0],
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          barber.specialty,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Visual
                  if (barber.isBooked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.green,
                            size: 20,
                          ),
                          Text(
                            barber.bookedTime ?? "",
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right, color: AppColors.gold),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Drawer Customizado
class _CustomDrawer extends StatelessWidget {
  const _CustomDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.charcoal,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.cardDark),
            accountName: const Text(
              "Ian Developer",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text(
              "ian@flutter.dev",
              style: TextStyle(color: AppColors.grey),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.gold,
              child: const Icon(
                Icons.person,
                color: AppColors.charcoal,
                size: 40,
              ),
            ),
          ),

          // NAVEGAÇÃO PARA PERFIL
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.white),
            title: const Text(
              "Meu Perfil",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context); // Fecha o Drawer primeiro
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ); // Importe a tela
            },
          ),

          // NAVEGAÇÃO PARA AGENDAMENTOS
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.white),
            title: const Text(
              "Meus Agendamentos",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context); // Fecha o Drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsScreen(),
                ),
              ); // Importe a tela
            },
          ),

          const Divider(color: AppColors.grey),

          // LOGOUT DIRETO NO DRAWER (OPCIONAL, JÁ TEM NA TELA DE PERFIL)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Sair",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
