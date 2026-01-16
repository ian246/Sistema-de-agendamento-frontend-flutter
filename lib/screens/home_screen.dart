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

import '../models/appointment_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();
  late Future<List<Barber>> _barbersFuture;
  String _userId = '';
  Future<List<Appointment>>? _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
      if (_userId.isNotEmpty) {
        _appointmentsFuture = api.getMyAppointments(_userId);
        _checkConfirmedAppointments();
      }
    });
  }

  Future<void> _checkConfirmedAppointments() async {
    try {
      final appointments = await api.getMyAppointments(_userId);
      final prefs = await SharedPreferences.getInstance();
      final notifiedIds = prefs.getStringList('notified_confirmed_ids') ?? [];

      // Filtra agendamentos confirmados, futuros e que ainda não foram notificados
      final newConfirmed = appointments.where((a) {
        final isConfirmed = a.status.toLowerCase() == 'confirmed' ||
            a.status.toLowerCase() == 'confirmado';
        final isNot notifiedIds.contains(a.id);
        return isConfirmed && !a.isPast && !notifiedIds.contains(a.id);
      }).toList();

      if (newConfirmed.isNotEmpty && mounted) {
        // Pega o primeiro para notificar (ou poderia ser uma lista)
        final appointment = newConfirmed.first;
        
        // Atualiza a lista de notificados
        notifiedIds.add(appointment.id);
        await prefs.setStringList('notified_confirmed_ids', notifiedIds);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Seu agendamento com ${appointment.barber.name} foi confirmado!"),
            backgroundColor: const Color(0xFF22C55E), // Green
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Ver Mais',
              textColor: Colors.white,
              onPressed: () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentsScreen(
                      highlightedAppointmentId: appointment.id,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Falha silenciosa na notificação para não travar o app
      debugPrint("Erro ao verificar notificações: $e");
    }
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

    if (!mounted) return;

    if (result != null && result is Map && result['booked'] == true) {
      // Simula o ID do novo agendamento (em produção viria do backend)
      final newAppointmentId = result['appointmentId']?.toString() ?? '1';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Agendamento solicitado para ${result['time']}!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver Mais',
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentsScreen(
                    highlightedAppointmentId: newAppointmentId,
                  ),
                ),
              );
            },
          ),
        ),
      );
      // Recarrega contagem
      _loadUserData();
    }
  }

  void _showProfileImageDialog(BuildContext context, Barber barber) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com nome e botão fechar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (barber.salonName != null &&
                            barber.salonName!.isNotEmpty)
                          Text(
                            barber.salonName!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          barber.name,
                          style: TextStyle(
                            color: barber.salonName != null
                                ? AppColors.grey
                                : AppColors.white,
                            fontSize: barber.salonName != null ? 14 : 18,
                            fontWeight: barber.salonName != null
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Imagem
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Image.network(
                  barber.salonImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha seu Profissional"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: FutureBuilder<List<Appointment>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                int activeCount = 0;
                if (snapshot.hasData) {
                  activeCount = snapshot.data!
                      .where(
                        (a) =>
                            !a.isPast &&
                            a.status.toLowerCase() != 'cancelled' &&
                            a.status.toLowerCase() != 'cancelado',
                      )
                      .length;
                }
                return Badge(
                  label: Text('$activeCount'),
                  isLabelVisible: activeCount > 0,
                  child: const Icon(Icons.menu),
                );
              },
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
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
                        GestureDetector(
                          onTap:
                              barber.salonImageUrl != null &&
                                  barber.salonImageUrl!.isNotEmpty
                              ? () => _showProfileImageDialog(context, barber)
                              : null,
                          child: Container(
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
                              backgroundImage:
                                  barber.salonImageUrl != null &&
                                      barber.salonImageUrl!.isNotEmpty
                                  ? NetworkImage(barber.salonImageUrl!)
                                  : null,
                              child:
                                  barber.salonImageUrl == null ||
                                      barber.salonImageUrl!.isEmpty
                                  ? Text(
                                      barber.name.isNotEmpty
                                          ? barber.name[0]
                                          : "?",
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome do Salão em destaque (se existir)
                              if (barber.salonName != null &&
                                  barber.salonName!.isNotEmpty)
                                Text(
                                  barber.salonName!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              // Nome do profissional
                              Text(
                                barber.name,
                                style: TextStyle(
                                  fontSize:
                                      barber.salonName != null &&
                                          barber.salonName!.isNotEmpty
                                      ? 14
                                      : 20,
                                  fontWeight:
                                      barber.salonName != null &&
                                          barber.salonName!.isNotEmpty
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color:
                                      barber.salonName != null &&
                                          barber.salonName!.isNotEmpty
                                      ? AppColors.grey
                                      : AppColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Endereço (se existir)
                              if (barber.address != null &&
                                  barber.address!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        barber.address!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(
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
  String _userId = '';
  Future<List<dynamic>>? _appointmentsFuture;
  final ApiService _apiService = ApiService();

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
      _userId = prefs.getString('userId') ?? '';
      _isLoading = false;

      if (_userId.isNotEmpty) {
        _appointmentsFuture = _apiService.getMyAppointments(_userId);
      }
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
            leading: FutureBuilder<List<dynamic>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                int activeCount = 0;
                if (snapshot.hasData) {
                  activeCount = snapshot.data!.where((a) => !a.isPast).length;
                }
                return Badge(
                  label: Text('$activeCount'),
                  isLabelVisible: activeCount > 0,
                  child: const Icon(Icons.history, color: AppColors.white),
                );
              },
            ),
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
