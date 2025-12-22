class Booking {
  final int id;
  final String userId;
  final int serviceId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? comment;
  final String? serviceTitle;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.comment,
    this.serviceTitle,
  });

  factory Booking.fromMap(Map<String, dynamic> m) {
    final services = m['services'];
    return Booking(
      id: (m['id'] as num).toInt(),
      userId: m['user_id'] as String,
      serviceId: (m['service_id'] as num).toInt(),
      startTime: DateTime.parse(m['start_time'] as String).toLocal(),
      endTime: DateTime.parse(m['end_time'] as String).toLocal(),
      status: (m['status'] as String?) ?? 'pending',
      comment: m['comment'] as String?,
      serviceTitle: services is Map ? services['title'] as String? : null,
    );
  }
}
