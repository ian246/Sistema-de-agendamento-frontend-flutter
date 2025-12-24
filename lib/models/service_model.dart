class BarberService {
  final String id;
  final String title;
  final String description;
  final double price;
  final int duration;

  BarberService({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
  });

  // Fábrica que transforma o JSON do Node.js em Objeto Dart
  factory BarberService.fromJson(Map<String, dynamic> json) {
    return BarberService(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      // O tryParse protege caso o banco mande "50" (int) ou "50.00" (string)
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      duration: int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 30,
    );
  }
}
