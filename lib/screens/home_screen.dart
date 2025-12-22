import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/barber_models.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'appointments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  late Future<List<Barber>> _barbersFuture;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  void _loadBarbers() {
    setState(() {
      _barbersFuture = api.getBarbers();
    });
  }

  void _goToBooking(Barber barber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingScreen(barber: barber)),
    );

    if (result != null && result is Map && result['booked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Agendamento solicitado para ${result['time']}!"),
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
      drawer: const _CustomDrawer(),
      body: FutureBuilder<List<Barber>>(
        future: _barbersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    "Erro ao carregar barbeiros.\nVerifique se o servidor está rodando.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadBarbers,
                    child: const Text("Tentar Novamente"),
                  ),
                ],
              ),
            );
          }

          final barbers = snapshot.data ?? [];
          if (barbers.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum barbeiro encontrado.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final barber = barbers[index];

              return InkWell(
                onTap: () => _goToBooking(barber),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),

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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.gold.withOpacity(0.2),
                        child: Text(
                          barber.name.isNotEmpty ? barber.name[0] : "?",
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

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
          );
        },
      ),
    );
  }
}

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
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.white),
            title: const Text(
              "Meu Perfil",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.white),
            title: const Text(
              "Meus Agendamentos",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.grey),
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
