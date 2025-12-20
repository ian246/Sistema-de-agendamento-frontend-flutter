import 'package:flutter/material.dart';
import '../theme.dart';
import '../mock_data.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Cores dinâmicas baseadas no status
    final statusColor = appointment.isPast ? AppColors.grey : AppColors.green;
    final statusText = appointment.isPast ? "Finalizado" : "Confirmado";
    final cardOpacity = appointment.isPast ? 0.6 : 1.0;

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: statusColor, width: 4), // Indicador lateral
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: Nome e Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.barber.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informações principais
            _buildInfoRow(Icons.content_cut, appointment.service),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              "${appointment.date.day}/${appointment.date.month} às ${appointment.time}",
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, appointment.location),

            const Divider(color: AppColors.grey, height: 24),

            // Rodapé: Preço
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Total: ", style: TextStyle(color: AppColors.grey)),
                Text(
                  "R\$ ${appointment.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
