import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/service.dart';
import '../models/booking.dart';

class DbService {
  SupabaseClient get _db => SupabaseConfig.client;

  String? get _uid => _db.auth.currentUser?.id;

  void _requireAuth() {
    if (_uid == null) throw const AuthException('Not authenticated');
  }

  // ---------- Services ----------
  Future<List<Service>> fetchActiveServices() async {
    final res = await _db
        .from('services')
        .select()
        .eq('is_active', true)
        .order('title');

    return (res as List).map((e) => Service.fromMap(e)).toList();
  }

  Future<List<Service>> fetchAllServicesAdmin() async {
    _requireAuth();
    final res = await _db.from('services').select().order('id', ascending: false);
    return (res as List).map((e) => Service.fromMap(e)).toList();
  }

  Future<void> upsertService({
    int? id,
    required String title,
    String? description,
    required int durationMinutes,
    required double price,
    required bool isActive,
  }) async {
    _requireAuth();

    final payload = {
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'is_active': isActive,
    };

    if (id == null) {
      await _db.from('services').insert(payload);
    } else {
      await _db.from('services').update(payload).eq('id', id);
    }
  }

  Future<void> deleteService(int id) async {
    _requireAuth();
    await _db.from('services').delete().eq('id', id);
  }

  // ---------- Bookings ----------
  Future<void> createBooking({
    required int serviceId,
    required DateTime startLocal,
    required DateTime endLocal,
    String? comment,
  }) async {
    _requireAuth();

    final startUtc = startLocal.toUtc().toIso8601String();
    final endUtc = endLocal.toUtc().toIso8601String();

    await _db.from('bookings').insert({
      'user_id': _uid!,
      'service_id': serviceId,
      'start_time': startUtc,
      'end_time': endUtc,
      'comment': comment,
      'status': 'pending',
    });
  }

  Future<List<Booking>> fetchMyBookings() async {
    _requireAuth();

    final res = await _db
        .from('bookings')
        .select('id,user_id,service_id,start_time,end_time,status,comment, services(title)')
        .order('start_time', ascending: false);

    return (res as List).map((e) => Booking.fromMap(e)).toList();
  }

  Future<void> cancelMyBooking(int bookingId) async {
    _requireAuth();
    await _db.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId);
  }

  // ---------- Admin ----------
  Future<List<Booking>> fetchAllBookingsAdmin() async {
    _requireAuth();

    final res = await _db
        .from('bookings')
        .select('id,user_id,service_id,start_time,end_time,status,comment, services(title)')
        .order('start_time', ascending: false);

    return (res as List).map((e) => Booking.fromMap(e)).toList();
  }

  Future<void> updateBookingStatusAdmin(int bookingId, String status) async {
    _requireAuth();
    await _db.from('bookings').update({'status': status}).eq('id', bookingId);
  }

  /// VIEW v_load_by_day (если view не создана — вернём пустой список)
  Future<List<Map<String, dynamic>>> fetchLoadReport() async {
    _requireAuth();

    try {
      final res = await _db.from('v_load_by_day').select().limit(30);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // если view отсутствует или нет доступа — не ломаем админку
      return <Map<String, dynamic>>[];
    }
  }
}
