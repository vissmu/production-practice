import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/booking.dart';
import '../utils/user_friendly_error.dart';
import '../widgets/app_shell.dart';
import '../services/auth_service.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final _db = DbService();
  final _auth = AuthService();

  bool _loading = true;
  String? _error;
  List<Booking> _items = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _load();
    try {
      final isAdmin = await _auth.isAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _db.fetchMyBookings();
      setState(() => _items = res);
    } catch (e) {
      setState(() => _error = userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _db.cancelMyBooking(id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бронирование отменено')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFFFA000);
      case 'done':
        return const Color(0xFF1E88E5);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'confirmed':
      case 'approved':
      case 'accepted':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    final body = Container(
      color: const Color(0xFFF9F7FE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? const Center(child: Text('Бронирований нет'))
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 64,
                              columns: const [
                                DataColumn(label: Text('Услуга')),
                                DataColumn(label: Text('Начало')),
                                DataColumn(label: Text('Конец')),
                                DataColumn(label: Text('Статус')),
                                DataColumn(label: Text('Действия')),
                              ],
                              rows: _items.map((b) {
                                final statusColor = _statusColor(b.status);
                                final canCancel = b.status != 'cancelled' && b.status != 'done';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(b.serviceTitle ?? 'Услуга #${b.serviceId}')),
                                    DataCell(Text(fmt.format(b.startTime))),
                                    DataCell(Text(fmt.format(b.endTime))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: statusColor.withOpacity(0.35)),
                                        ),
                                        child: Text(
                                          b.status,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      canCancel
                                          ? OutlinedButton(
                                              onPressed: () => _cancel(b.id),
                                              child: const Text('Отменить'),
                                            )
                                          : const Text('—'),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
      ),
    );

    return AppShell(
      title: 'Мои бронирования',
      body: body,
      selectedIndex: 1,
      showAdmin: _isAdmin,
    );
  }
}
