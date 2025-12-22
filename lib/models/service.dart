class Service {
  final int id;
  final String title;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;

  Service({
    required this.id,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
  });

  factory Service.fromMap(Map<String, dynamic> m) => Service(
        id: m['id'] as int,
        title: m['title'] as String,
        description: m['description'] as String?,
        durationMinutes: (m['duration_minutes'] as num).toInt(),
        price: (m['price'] as num).toDouble(),
        isActive: (m['is_active'] as bool?) ?? true,
      );
}
