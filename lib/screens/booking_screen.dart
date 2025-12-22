import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/theme.dart';
import '../models/barber_models.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  final Barber barber;
  const BookingScreen({super.key, required this.barber});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService api = ApiService();

  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool _isLoading = false;

  final String myClientId = dotenv.env['TEST_CLIENT_ID'] ?? '';
  final String myServiceId = dotenv.env['TEST_SERVICE_ID'] ?? '';

  final List<String> _timeSlots = [
    "09:00",
    "10:00",
    "11:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "18:00",
  ];

  void _submitBooking() async {
    if (_selectedTime == null) return;

    setState(() => _isLoading = true);

    try {
      await api.createAppointment(
        providerId: widget.barber.id,
        serviceId: myServiceId,
        date: _selectedDay,
        time: _selectedTime!,
      );

      if (mounted) {
        Navigator.pop(context, {'booked': true, 'time': _selectedTime});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString().replaceAll("Exception:", "")}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Marcar Horário")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.cardDark,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.gold,
                  child: Text(
                    widget.barber.name.isNotEmpty ? widget.barber.name[0] : "?",
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.barber.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  widget.barber.specialty,
                  style: const TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selecione a Data",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2026),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.gold,
                                onPrimary: AppColors.charcoal,
                                surface: AppColors.cardDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _selectedDay = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Horários Disponíveis",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _timeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.charcoal
                              : AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setState(
                            () => _selectedTime = selected ? time : null,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Estimado:",
                      style: TextStyle(color: AppColors.grey),
                    ),
                    Text(
                      "R\$ 45,00",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedTime == null || _isLoading)
                        ? null
                        : _submitBooking,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.charcoal,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("CONFIRMAR AGENDAMENTO"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
