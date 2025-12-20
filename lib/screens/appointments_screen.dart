import 'package:flutter/material.dart';
import '../theme.dart';
import '../mock_data.dart';
import '../widgets/appointment_card.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filtrando as listas
    final activeAppointments = mockAppointments
        .where((a) => !a.isPast)
        .toList();
    final pastAppointments = mockAppointments.where((a) => a.isPast).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Meus Agendamentos"),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.grey,
            tabs: [
              Tab(text: "Ativos"),
              Tab(text: "Histórico"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba de Ativos
            _buildList(activeAppointments, "Nenhum agendamento ativo."),
            // Aba de Histórico
            _buildList(pastAppointments, "Nenhum histórico encontrado."),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Appointment> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 60, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return AppointmentCard(appointment: list[index]);
      },
    );
  }
}
