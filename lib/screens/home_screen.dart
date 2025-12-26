import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../models/barber_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

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
          backgroundColor: AppColors.primary,
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
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString().replaceFirst(
              'Exception: ',
              '',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_outlined,
                        color: Colors.red,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Erro de Conexão",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadBarbers,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Tentar Novamente"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
            padding: const EdgeInsets.all(20),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final barber = barbers[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _goToBooking(barber),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: barber.isBooked
                          ? LinearGradient(
                              colors: [
                                AppColors.surface,
                                AppColors.primary.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: barber.isBooked ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: barber.isBooked
                            ? AppColors.primary
                            : AppColors.grey.withOpacity(0.1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barber.isBooked
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: barber.isBooked
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF1FD89A),
                                    ],
                                  )
                                : null,
                            color: barber.isBooked
                                ? null
                                : AppColors.primary.withOpacity(0.2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.background,
                            child: Text(
                              barber.name.isNotEmpty ? barber.name[0] : "?",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.content_cut,
                                    size: 14,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    barber.specialty,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (barber.isBooked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF1FD89A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  barber.bookedTime ?? "",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
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

class _CustomDrawer extends StatefulWidget {
  const _CustomDrawer();

  @override
  State<_CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<_CustomDrawer> {
  String _userName = 'Cliente';
  String _userEmail = 'Email não disponível';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Cliente';
      _userEmail = prefs.getString('userEmail') ?? 'Email não disponível';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pega a primeira letra do nome para o avatar (ex: "G" de Gabi)
    final String initial = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : "?";

    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            accountName: _isLoading
                ? const Text('Carregando...')
                : Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
            accountEmail: _isLoading
                ? const Text('...')
                : Text(
                    _userEmail,
                    style: const TextStyle(color: AppColors.grey),
                  ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // --- Itens do Menu ---
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.white),
            title: const Text(
              "Meu Perfil",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
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

          // BOTÃO SAIR (LOGOUT)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Sair",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              // Usa o AuthService para fazer logout completo
              final authService = AuthService();
              await authService.signOut();

              // Volta para a tela de Login e remove o histórico
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
