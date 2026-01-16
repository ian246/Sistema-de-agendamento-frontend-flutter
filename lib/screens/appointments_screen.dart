import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../models/appointment_models.dart';
import '../services/api_service.dart';
import '../widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  final String? highlightedAppointmentId;

  const AppointmentsScreen({super.key, this.highlightedAppointmentId});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService api = ApiService();
  Future<List<Appointment>>? _appointmentsFuture;
  String? myClientId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Carrega o userId do SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      if (mounted) {
        setState(() {
          myClientId = userId;
        });
        _loadAppointments();
      }
    }
  }

  void _loadAppointments() {
    if (myClientId == null) return;
    setState(() {
      _appointmentsFuture = api.getMyAppointments(myClientId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Meus Agendamentos"),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            tabs: [
              Tab(text: "Ativos"),
              Tab(text: "Cancelados"),
              Tab(text: "Histórico"),
            ],
          ),
        ),
        body: _appointmentsFuture == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : FutureBuilder<List<Appointment>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Erro: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  // Ordena por data (mais próximo primeiro)
                  list.sort((a, b) => a.date.compareTo(b.date));

                  // Filtros
                  final cancelled = list
                      .where(
                        (a) =>
                            a.status.toLowerCase() == 'cancelled' ||
                            a.status.toLowerCase() == 'cancelado',
                      )
                      .toList();

                  final past = list
                      .where(
                        (a) =>
                            a.isPast &&
                            a.status.toLowerCase() != 'cancelled' &&
                            a.status.toLowerCase() != 'cancelado',
                      )
                      .toList();

                  // Ativos (Futuros e não cancelados)
                  final active = list
                      .where(
                        (a) =>
                            !a.isPast &&
                            a.status.toLowerCase() != 'cancelled' &&
                            a.status.toLowerCase() != 'cancelado',
                      )
                      .toList();

                  return TabBarView(
                    children: [
                      _buildActiveTab(active),
                      _buildList(cancelled, "Nenhum agendamento cancelado."),
                      _buildList(past, "Histórico vazio."),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActiveTab(List<Appointment> activeAppointments) {
    if (activeAppointments.isEmpty) {
      return const Center(
        child: Text(
          "Você não tem agendamentos futuros.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final pending = activeAppointments
        .where(
          (a) =>
              a.status.toLowerCase() == 'pending' ||
              a.status.toLowerCase() == 'pendente' ||
              a.status.toLowerCase() == 'aguardando',
        )
        .toList();

    final confirmed = activeAppointments
        .where(
          (a) =>
              a.status.toLowerCase() == 'confirmed' ||
              a.status.toLowerCase() == 'confirmado',
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PENDING SECTION ---
          if (pending.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Aguardando Confirmação (${pending.length})",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.map(
              (appointment) => AppointmentCard(
                appointment: appointment,
                onUpdate: _loadAppointments,
                isHighlighted:
                    appointment.id.toString() ==
                    widget.highlightedAppointmentId,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.grey),
            const SizedBox(height: 24),
          ],

          // --- CONFIRMED SECTION ---
          if (confirmed.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.event_available, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  "Confirmados",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...confirmed.map(
              (appointment) => AppointmentCard(
                appointment: appointment,
                onUpdate: _loadAppointments,
                isHighlighted:
                    appointment.id.toString() ==
                    widget.highlightedAppointmentId,
              ),
            ),
          ],

          if (confirmed.isEmpty && pending.isEmpty)
            const Center(
              child: Text(
                "Nenhum agendamento ativo.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<Appointment> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => AppointmentCard(
        appointment: list[index],
        onUpdate: _loadAppointments,
      ),
    );
  }
}
