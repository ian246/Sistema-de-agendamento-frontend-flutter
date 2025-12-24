import 'package:flutter/material.dart';
import 'package:Bcorte/models/appointment_models.dart';
import '../utils/theme.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusColor = appointment.isPast ? AppColors.grey : AppColors.primary;
    final statusText = appointment.isPast ? "Finalizado" : "Confirmado";
    final cardOpacity = appointment.isPast ? 0.6 : 1.0;

    return AnimatedOpacity(
      opacity: cardOpacity,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: !appointment.isPast
              ? LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: appointment.isPast ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: !appointment.isPast
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.grey.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: !appointment.isPast
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment.barber.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: !appointment.isPast
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF1FD89A)],
                          )
                        : null,
                    color: appointment.isPast
                        ? AppColors.grey.withOpacity(0.2)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !appointment.isPast
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: !appointment.isPast
                          ? Colors.black
                          : AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(Icons.content_cut, appointment.service),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.calendar_today,
              "${appointment.date.day}/${appointment.date.month} às ${appointment.time}",
            ),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.location_on, appointment.location),

            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.grey.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "R\$ ${appointment.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
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
