import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../utils/user_friendly_error.dart';
import '../widgets/app_shell.dart';
import '../services/auth_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final _db = DbService();
  final _auth = AuthService();

  bool _loading = true;
  String? _error;

  List<Service> _services = [];
  List<Booking> _bookings = [];
  List<Map<String, dynamic>> _report = [];
  bool _isAdmin = false;

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    try {
      final isAdmin = await _auth.isAdmin();
      setState(() => _isAdmin = isAdmin);
    } catch (_) {}
    await _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final services = await _db.fetchAllServicesAdmin();
      final bookings = await _db.fetchAllBookingsAdmin();

      List<Map<String, dynamic>> report = [];
      try {
        report = await _db.fetchLoadReport();
      } catch (_) {
        // view может отсутствовать — покажем подсказку в UI
        report = [];
      }

      setState(() {
        _services = services;
        _bookings = bookings;
        _report = report;
      });
    } catch (e) {
      setState(() => _error = userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editService({Service? s}) async {
    final title = TextEditingController(text: s?.title ?? '');
    final desc = TextEditingController(text: s?.description ?? '');
    final dur = TextEditingController(text: (s?.durationMinutes ?? 60).toString());
    final price = TextEditingController(text: (s?.price ?? 1000).toString());
    bool isActive = s?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s == null ? 'Добавить услугу' : 'Редактировать услугу'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
                const SizedBox(height: 10),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Описание')),
                const SizedBox(height: 10),
                TextField(
                  controller: dur,
                  decoration: const InputDecoration(labelText: 'Длительность (мин)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => isActive = v,
                  title: const Text('Активна'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _db.upsertService(
        id: s?.id,
        title: title.text.trim(),
        description: desc.text.trim().isEmpty ? null : desc.text.trim(),
        durationMinutes: int.tryParse(dur.text.trim()) ?? 60,
        price: double.tryParse(price.text.trim()) ?? 0,
        isActive: isActive,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      await _db.deleteService(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
    }
  }

  // ВАЖНО: здесь убрал "approved", чтобы не падало на enum.
  // Если ты добавишь approved в enum — можешь вернуть пункт.
  Future<void> _setStatus(int bookingId, String status) async {
    try {
      await _db.updateBookingStatusAdmin(bookingId, status);
      _load();
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
              : Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                controller: _tabs,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: const [
                                  Tab(text: 'Услуги'),
                                  Tab(text: 'Бронирования'),
                                  Tab(text: 'Отчёт'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Обновить'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          // -------------------- SERVICES TAB --------------------
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Услуги',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _editService(),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Добавить'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (_, c) {
                                      final cols = c.maxWidth >= 1200 ? 3 : 2;
                                      return GridView.builder(
                                        itemCount: _services.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          childAspectRatio: 2.9,
                                        ),
                                        itemBuilder: (_, i) {
                                          final s = _services[i];
                                          return Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEEEAFE),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: const Icon(Icons.miscellaneous_services_rounded),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          s.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          '${s.durationMinutes} мин · ${s.price.toStringAsFixed(2)} ₽',
                                                          style: const TextStyle(color: Color(0xFF5A5A5A)),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: (s.isActive ? const Color(0xFF43A047) : const Color(0xFFE53935)).withOpacity(0.12),
                                                                borderRadius: BorderRadius.circular(999),
                                                                border: Border.all(
                                                                  color: (s.isActive ? const Color(0xFF43A047) : const Color(0xFFE53935)).withOpacity(0.35),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                s.isActive ? 'активна' : 'скрыта',
                                                                style: TextStyle(
                                                                  color: s.isActive ? const Color(0xFF43A047) : const Color(0xFFE53935),
                                                                  fontWeight: FontWeight.w800,
                                                                ),
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Редактировать',
                                                        onPressed: () => _editService(s: s),
                                                        icon: const Icon(Icons.edit_rounded),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Удалить',
                                                        onPressed: () => _deleteService(s.id),
                                                        icon: const Icon(Icons.delete_rounded),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // -------------------- BOOKINGS TAB --------------------
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowHeight: 44,
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 66,
                                    columns: const [
                                      DataColumn(label: Text('Услуга')),
                                      DataColumn(label: Text('Начало')),
                                      DataColumn(label: Text('Конец')),
                                      DataColumn(label: Text('Статус')),
                                      DataColumn(label: Text('Изменить')),
                                    ],
                                    rows: _bookings.map((b) {
                                      final statusColor = _statusColor(b.status);
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
                                            PopupMenuButton<String>(
                                              onSelected: (v) => _setStatus(b.id, v),
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(value: 'pending', child: Text('pending')),
                                                PopupMenuItem(value: 'confirmed', child: Text('confirmed')),
                                                PopupMenuItem(value: 'done', child: Text('done')),
                                                PopupMenuItem(value: 'cancelled', child: Text('cancelled')),
                                              ],
                                              child: OutlinedButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.tune_rounded),
                                                label: const Text('Статус'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // -------------------- REPORT TAB --------------------
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: _report.isEmpty
                                ? Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text('Отчёт недоступен', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                          SizedBox(height: 10),
                                          Text(
                                            'В базе не найдено представление v_load_by_day.\n\n'
                                            'Если хочешь отчёт, создай VIEW в Supabase SQL Editor.',
                                            style: TextStyle(color: Color(0xFF5A5A5A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    itemCount: _report.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 2.6,
                                    ),
                                    itemBuilder: (_, i) {
                                      final r = _report[i];
                                      final day = '${r['day'] ?? r['date'] ?? '-'}';
                                      final cnt = '${r['cnt'] ?? r['count'] ?? '-'}';
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 8),
                                              Text('Бронирований: $cnt', style: const TextStyle(color: Color(0xFF5A5A5A))),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );

    return AppShell(
      title: 'Админ-панель',
      body: body,
      selectedIndex: 2,
      showAdmin: _isAdmin,
    );
  }
}
