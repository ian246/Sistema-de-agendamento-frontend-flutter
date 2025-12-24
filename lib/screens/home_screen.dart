import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../models/barber_models.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
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
  // Pega os dados do usuário logado na memória do celular
  final user = Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    // Tenta pegar o nome salvo no cadastro. Se não tiver, usa "Cliente"
    final String name = user?.userMetadata?['full_name'] ?? "Cliente";
    final String email = user?.email ?? "Email não disponível";

    // Pega a primeira letra do nome para o avatar (ex: "G" de Gabi)
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            // AQUI ESTÁ A MUDANÇA: Usamos as variáveis name e email
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              email,
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

          // --- Itens do Menu (Mantive igual ao seu) ---
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.white),
            title: const Text(
              "Meu Perfil",
              style: TextStyle(color: AppColors.white),
            ),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              // Adicione a navegação para ProfileScreen se tiver
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
              // 1. Desloga do Supabase
              await Supabase.instance.client.auth.signOut();

              // 2. Volta para a tela de Login e remove o histórico de telas
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
