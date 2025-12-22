import 'barber_models.dart';

class Appointment {
  final String id;
  final Barber barber;
  final DateTime date;
  final String time;
  final String service;
  final double price;
  final String location;
  final bool isPast;

  Appointment({
    required this.id,
    required this.barber,
    required this.date,
    required this.time,
    required this.service,
    required this.price,
    required this.location,
    required this.isPast,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final DateTime fullDate = DateTime.parse(json['start_time']);
    final providerData = json['provider'] ?? {};
    final serviceData = json['service'] ?? {};

    return Appointment(
      id: json['id'],
      barber: Barber(
        id: json['provider_id'],

        name: providerData['full_name'] ?? 'Barbeiro',
        specialty: 'Profissional',
      ),
      date: fullDate,
      time: "${fullDate.hour}:${fullDate.minute.toString().padLeft(2, '0')}",
      service: serviceData['title'] ?? 'Serviço',
      price: (json['price'] as num).toDouble(),
      location: "Unidade Principal",
      isPast: fullDate.isBefore(DateTime.now()),
    );
  }
}
