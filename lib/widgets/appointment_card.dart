import 'package:flutter/material.dart';
import 'package:Bcorte/models/appointment_models.dart';
import '../utils/theme.dart';
import '../services/api_service.dart'; // Import ApiService

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onUpdate;
  final bool isHighlighted;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onUpdate,
    this.isHighlighted = false,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHighlightActive = false;

  @override
  void initState() {
    super.initState();
    _isHighlightActive = widget.isHighlighted;

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_isHighlightActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppointmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      setState(() {
        _isHighlightActive = widget.isHighlighted;
      });
      if (_isHighlightActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stopHighlight() {
    if (_isHighlightActive) {
      setState(() {
        _isHighlightActive = false;
      });
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (widget.appointment.status.toLowerCase()) {
      case 'cancelled':
      case 'cancelado':
        statusColor = Colors.red;
        statusText = 'Cancelado';
        break;
      case 'pending':
      case 'pendente':
        statusColor = Colors.orange;
        statusText = 'Aguardando';
        break;
      case 'confirmed':
      case 'confirmado':
        statusColor = const Color(0xFF22C55E);
        statusText = 'Confirmado';
        break;
      default:
        statusColor = AppColors.primary;
        statusText = 'Pendente';
    }

    if (widget.appointment.isPast &&
        widget.appointment.status.toLowerCase() != 'cancelled' &&
        widget.appointment.status.toLowerCase() != 'cancelado') {
      statusText = 'Finalizado';
      statusColor = AppColors.grey;
    }

    final cardOpacity = widget.appointment.isPast ? 0.8 : 1.0;

    return GestureDetector(
      onTap: _stopHighlight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _isHighlightActive ? _animation.value : 1.0;
          final borderGlow = _isHighlightActive
              ? BoxShadow(
                  color: statusColor.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              : BoxShadow(
                  color: !widget.appointment.isPast
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                );

          return Transform.scale(
            scale: scale,
            child: AnimatedOpacity(
              opacity: cardOpacity,
              duration: const Duration(milliseconds: 300),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: !widget.appointment.isPast
                      ? LinearGradient(
                          colors: [
                            AppColors.surface,
                            statusColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.appointment.isPast ? AppColors.surface : null,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isHighlightActive
                        ? statusColor
                        : (!widget.appointment.isPast
                              ? statusColor.withOpacity(0.3)
                              : AppColors.grey.withOpacity(0.1)),
                    width: _isHighlightActive ? 3 : 2,
                  ),
                  boxShadow: [borderGlow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.appointment.barber.name,
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
                            gradient: !widget.appointment.isPast
                                ? LinearGradient(
                                    colors: [
                                      statusColor,
                                      statusColor.withOpacity(0.8),
                                    ],
                                  )
                                : null,
                            color: widget.appointment.isPast
                                ? AppColors.grey.withOpacity(0.2)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !widget.appointment.isPast
                                ? [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: !widget.appointment.isPast
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

                    _buildInfoRow(
                      Icons.content_cut,
                      widget.appointment.service,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.calendar_today,
                      "${widget.appointment.date.day}/${widget.appointment.date.month} às ${widget.appointment.time}",
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.location_on,
                      widget.appointment.location,
                    ),

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
                            "R\$ ${widget.appointment.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((widget.appointment.status.toLowerCase() ==
                                'cancelled' ||
                            widget.appointment.status.toLowerCase() ==
                                'cancelado') &&
                        widget.appointment.cancellationReason != null &&
                        widget.appointment.cancellationReason!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Motivo: ${widget.appointment.cancellationReason}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botão de Cancelar (apenas para agendamentos pendentes)
                    if (!widget.appointment.isPast &&
                        (widget.appointment.status.toLowerCase() == 'pending' ||
                            widget.appointment.status.toLowerCase() ==
                                'pendente' ||
                            widget.appointment.status.toLowerCase() ==
                                'aguardando'))
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: const Text("Cancelar Agendamento"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Cancelar Agendamento",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Deseja realmente cancelar? Se sim, informe o motivo:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ex: Imprevisto, mudança de horário...",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, informe um motivo.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Fecha dialog
              _cancelAppointment(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirmar Cancelamento"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, String reason) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final api = ApiService();
      await api.cancelAppointment(widget.appointment.id, reason);

      if (context.mounted) {
        Navigator.pop(context); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento cancelado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate?.call();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
