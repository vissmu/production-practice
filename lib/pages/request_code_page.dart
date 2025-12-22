import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/user_friendly_error.dart';
import 'otp_page.dart';

class RequestCodePage extends StatefulWidget {
  const RequestCodePage({super.key});

  @override
  State<RequestCodePage> createState() => _RequestCodePageState();
}

class _RequestCodePageState extends State<RequestCodePage> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final fullName = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    try {
      await _auth.sendOtp(
        email: email,
        fullName: fullName.isEmpty ? null : fullName,
        phone: phone.isEmpty ? null : phone,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpPage(email: email)),
      );
    } catch (e) {
      setState(() => _error = userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Вход по коду',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Введите email — мы отправим одноразовый код для входа.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5A5A5A)),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@gmail.com',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ФИО (необязательно)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Телефон (необязательно)',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _sendCode,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mail_outline_rounded),
                      label: const Text('Получить код'),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'Если email существует, код будет отправлен.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
