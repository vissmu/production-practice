import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/services_page.dart';
import '../pages/my_bookings_page.dart';
import '../pages/admin_page.dart';

class AppShell extends StatefulWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final bool showAdmin;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    required this.selectedIndex,
    required this.showAdmin,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _auth = AuthService();

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEEAFE) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFEDEAFD)),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Computer Master\nBooking',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    _navButton(
                      icon: Icons.home_rounded,
                      label: 'Услуги',
                      selected: widget.selectedIndex == 0,
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const ServicesPage()),
                        (_) => false,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _navButton(
                      icon: Icons.event_note_rounded,
                      label: 'Мои бронирования',
                      selected: widget.selectedIndex == 1,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                      ),
                    ),

                    if (widget.showAdmin) ...[
                      const SizedBox(height: 8),
                      _navButton(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Админ-панель',
                        selected: widget.selectedIndex == 2,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminPage()),
                        ),
                      ),
                    ],

                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Выйти'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top bar
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Обновить',
                          onPressed: () {
                            // страницы сами решают, что обновлять (по setState / reload)
                            // тут просто визуальная кнопка
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: widget.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
