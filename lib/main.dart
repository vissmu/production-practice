import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'theme/app_theme.dart';
import 'widgets/desktop_only.dart';

import 'pages/request_code_page.dart';
import 'pages/services_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        '/': (_) => DesktopOnly(
              child: StreamBuilder<AuthState>(
                stream: supabase.auth.onAuthStateChange,
                builder: (_, __) {
                  final user = supabase.auth.currentUser;
                  if (user == null) return const RequestCodePage();
                  return const ServicesPage();
                },
              ),
            ),
      },
    );
  }
}
