class Barber {
  final String id;
  final String name;
  final String specialty;
  bool isBooked;
  String? bookedTime; // Ex: "14:30"

  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    this.isBooked = false,
    this.bookedTime,
  });
}

// Lista simulada (Mock)
List<Barber> mockBarbers = [
  Barber(id: '1', name: 'Thiago Silva', specialty: 'Degradê Navalhado'),
  Barber(id: '2', name: 'Douglas Costa', specialty: 'Barba Terapia'),
  Barber(id: '3', name: 'Luis Felipe', specialty: 'Corte Clássico'),
  Barber(id: '4', name: 'Jacaré Barber', specialty: 'Freestyle & Desenhos'),
];

// Adicione abaixo da classe Barber existente

class Appointment {
  final String id;
  final Barber barber;
  final DateTime date;
  final String time;
  final String service;
  final double price;
  final String location;
  final bool isPast; // Define se é histórico ou ativo

  Appointment({
    required this.id,
    required this.barber,
    required this.date,
    required this.time,
    required this.service,
    required this.price,
    required this.location,
    this.isPast = false,
  });
}

// Mock de Agendamentos
List<Appointment> mockAppointments = [
  // Agendamento Futuro (Ativo)
  Appointment(
    id: '101',
    barber: mockBarbers[0], // Thiago
    date: DateTime.now().add(const Duration(days: 1)),
    time: "14:00",
    service: "Corte Degradê",
    price: 45.00,
    location: "Rua das Flores, 123 - Centro",
    isPast: false,
  ),
  // Agendamento Passado (Histórico)
  Appointment(
    id: '102',
    barber: mockBarbers[2], // Luis
    date: DateTime.now().subtract(const Duration(days: 5)),
    time: "10:00",
    service: "Barba Terapia",
    price: 35.00,
    location: "Av. Paulista, 900 - Bela Vista",
    isPast: true,
  ),
  Appointment(
    id: '103',
    barber: mockBarbers[3], // Jacaré
    date: DateTime.now().subtract(const Duration(days: 20)),
    time: "16:00",
    service: "Corte + Barba",
    price: 70.00,
    location: "Rua Augusta, 500",
    isPast: true,
  ),
];
