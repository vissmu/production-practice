String userFriendlyError(Object e) {
  final raw = e.toString();

  // rate limit
  if (raw.contains('over_email_send_rate_limit')) {
    // Supabase часто пишет "only request this after X seconds"
    final match = RegExp(r'after (\d+) seconds').firstMatch(raw);
    final seconds = match != null ? match.group(1) : null;
    return seconds == null
        ? 'Слишком часто. Попробуйте чуть позже.'
        : 'Слишком часто. Попробуйте снова через $seconds сек.';
  }

  // SMTP / provider generic
  if (raw.contains('Error sending') ||
      raw.contains('unexpected_failure') ||
      raw.contains('statusCode: 500')) {
    return 'Не удалось отправить код. Попробуйте позже.';
  }

  // invalid otp
  if (raw.contains('otp') && raw.contains('invalid')) {
    return 'Неверный код. Проверьте и попробуйте снова.';
  }

  // email not confirmed / etc.
  if (raw.contains('email_not_confirmed')) {
    return 'Почта не подтверждена. Проверьте входящие письма.';
  }

  // fallback
  return 'Ошибка. ${raw.length > 120 ? raw.substring(0, 120) + '…' : raw}';
}
