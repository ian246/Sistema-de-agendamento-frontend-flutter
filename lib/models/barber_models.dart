class Barber {
  final String id;
  final String name;
  final String specialty;
  final String? salonName;
  final String? address;
  final String? phone;
  final String? salonImageUrl;
  bool isBooked;
  String? bookedTime;

  Barber({
    required this.id,
    required this.name,
    required this.specialty,
    this.salonName,
    this.address,
    this.phone,
    this.salonImageUrl,
    this.isBooked = false,
    this.bookedTime,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      name: json['full_name'] ?? 'Nome Desconhecido',
      specialty: json['specialty'] ?? 'Corte & Barba',
      salonName: json['salon_name'],
      address: json['address'],
      phone: json['phone'],
      salonImageUrl: json['salon_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': name,
      'specialty': specialty,
      'salon_name': salonName,
      'address': address,
      'phone': phone,
      'salon_image_url': salonImageUrl,
    };
  }
}
