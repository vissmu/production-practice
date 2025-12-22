import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ikpaxaucyomjraqqaxqv.supabase.co';
  static const String anonKey = 'sb_publishable_8_oInM95doSaWdYcywGsTg_d4Pbw6RM';

  static SupabaseClient get client => Supabase.instance.client;
}
