import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../services/db_service.dart';
import '../utils/user_friendly_error.dart';
import '../widgets/app_shell.dart';
import '../services/auth_service.dart';

class BookingCreatePage extends StatefulWidget {
  final Service service;
  const BookingCreatePage({super.key, required this.service});

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  final _db = DbService();
  final _auth = AuthService();

  DateTime? _date;
  TimeOfDay? _time;
  final _comment = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final isAdmin = await _auth.isAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (_) {
      // ничего страшного
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _create() async {
    setState(() => _error = null);

    if (_date == null || _time == null) {
      setState(() => _error = 'Выберите дату и время.');
      return;
    }

    final startLocal = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    final endLocal = startLocal.add(Duration(minutes: widget.service.durationMinutes));

    setState(() => _loading = true);

    try {
      await _db.createBooking(
        serviceId: widget.service.id,
        startLocal: startLocal,
        endLocal: endLocal,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бронирование создано')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd.MM.yyyy');
    final dateStr = _date == null ? 'Не выбрана' : fmtDate.format(_date!);
    final timeStr = _time == null ? 'Не выбрано' : _time!.format(context);

    final body = Container(
      color: const Color(0xFFF9F7FE),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: form
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEAFE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.build_rounded),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.service.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.service.durationMinutes} мин · ${widget.service.price.toStringAsFixed(2)} ₽',
                                  style: const TextStyle(color: Color(0xFF5A5A5A)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Назад'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Выберите дату и время',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loading ? null : _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE7E4FF)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month_rounded),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Дата', style: TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 4),
                                              Text(dateStr, style: const TextStyle(color: Color(0xFF5A5A5A))),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loading ? null : _pickTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE7E4FF)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Время', style: TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 4),
                                              Text(timeStr, style: const TextStyle(color: Color(0xFF5A5A5A))),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: _comment,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Комментарий (необязательно)',
                              hintText: 'Например: ноутбук сильно шумит',
                            ),
                          ),

                          const SizedBox(height: 12),
                          if (_error != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8E8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFFC9C9)),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFFB00020), fontWeight: FontWeight.w700),
                              ),
                            ),

                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _create,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Забронировать'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // RIGHT: summary
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Сводка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          _kv('Услуга', widget.service.title),
                          _kv('Длительность', '${widget.service.durationMinutes} мин'),
                          _kv('Цена', '${widget.service.price.toStringAsFixed(2)} ₽'),
                          const Divider(height: 18),
                          _kv('Дата', dateStr),
                          _kv('Время', timeStr),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Подсказка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          SizedBox(height: 10),
                          Text(
                            'После создания бронирования оно появится в разделе “Мои бронирования”.\n'
                            'Администратор сможет подтвердить или отменить запись.',
                            style: TextStyle(color: Color(0xFF5A5A5A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AppShell(
      title: 'Бронирование',
      body: body,
      selectedIndex: 0,
      showAdmin: _isAdmin,
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Color(0xFF6B6B6B)))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
