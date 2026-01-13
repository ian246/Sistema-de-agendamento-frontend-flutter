class ServiceModel {
  final String id;
  final String title;
  final double price;
  final int duration;
  final String? description;

  ServiceModel({
    required this.id,
    required this.title,
    required this.price,
    required this.duration,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      // Backend pode retornar 'title' ou 'name', suporta ambos
      title: json['title'] ?? json['name'] ?? '',
      // Trata null com defaults para evitar TypeError
      price: (json['price'] ?? 0 as num).toDouble(),
      duration: json['duration'] ?? json['duration_minutes'] ?? 30,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'duration': duration,
      'description': description,
    };
  }
}
