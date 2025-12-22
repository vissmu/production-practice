import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class AuthService {
  SupabaseClient get _sb => SupabaseConfig.client;

  Future<void> sendOtp({
    required String email,
    String? fullName,
    String? phone,
  }) async {
    // В meta укажем данные — триггер может их подхватить в profiles
    await _sb.auth.signInWithOtp(
      email: email,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await _sb.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  Future<bool> isAdmin() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;

    final res = await _sb
        .from('profiles')
        .select('is_admin')
        .eq('id', uid)
        .maybeSingle();

    if (res == null) return false;
    return (res['is_admin'] as bool?) ?? false;
  }
}
