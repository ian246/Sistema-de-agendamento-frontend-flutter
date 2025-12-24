import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../models/appointment_models.dart';
import '../services/api_service.dart';
import '../widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService api = ApiService();
  late Future<List<Appointment>> _appointmentsFuture;

  final String myClientId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = api.getMyAppointments(myClientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Meus Agendamentos"),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            tabs: [
              Tab(text: "Ativos"),
              Tab(text: "Histórico"),
            ],
          ),
        ),
        body: FutureBuilder<List<Appointment>>(
          future: _appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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

            final active = list.where((a) => !a.isPast).toList();
            final past = list.where((a) => a.isPast).toList();

            return TabBarView(
              children: [
                _buildList(active, "Você não tem agendamentos futuros."),
                _buildList(past, "Histórico vazio."),
              ],
            );
          },
        ),
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
      itemBuilder: (context, index) =>
          AppointmentCard(appointment: list[index]),
    );
  }
}
