class Barber {
  final String id;
  final String name;
  final String specialty;
  bool isBooked;
  String? bookedTime;

  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    this.isBooked = false,
    this.bookedTime,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      name: json['full_name'] ?? 'Nome Desconhecido',
      specialty: 'Corte & Barba',
    );
  }
}
