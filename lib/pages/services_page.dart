import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../models/service.dart';
import '../widgets/app_shell.dart';
import 'booking_create_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _db = DbService();
  final _auth = AuthService();

  bool _loading = true;
  bool _isAdmin = false;
  List<Service> _services = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final services = await _db.fetchActiveServices();
      final isAdmin = await _auth.isAdmin();
      setState(() {
        _services = services;
        _isAdmin = isAdmin;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFFF9F7FE),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // header card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Выберите услугу и забронируйте удобное время',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
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
                        child: LayoutBuilder(
                          builder: (_, c) {
                            final w = c.maxWidth;
                            final cols = w >= 1300 ? 3 : 2;

                            return GridView.builder(
                              itemCount: _services.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 3.3,
                              ),
                              itemBuilder: (_, i) {
                                final s = _services[i];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => BookingCreatePage(service: s)),
                                    );
                                    _load();
                                  },
                                  child: Card(
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
                                            child: const Icon(Icons.build_rounded),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${s.durationMinutes} мин · ${s.price.toStringAsFixed(2)} ₽',
                                                  style: const TextStyle(color: Color(0xFF5A5A5A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded),
                                        ],
                                      ),
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
    );

    return AppShell(
      title: 'Услуги',
      body: body,
      selectedIndex: 0,
      showAdmin: _isAdmin,
    );
  }
}
