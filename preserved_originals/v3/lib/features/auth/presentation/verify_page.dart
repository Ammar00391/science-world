import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_service.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
  bool _canResend = true;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final email = GoRouterState.of(context).uri.queryParameters['email'];
    if (email != null && email.isNotEmpty && _email.text.isEmpty) {
      _email.text = email;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  Future<void> _verify() async {
    if (!_isValidEmail(_email.text) || _code.text.trim().isEmpty) {
      setState(() => _error = 'أدخل بريدًا صحيحًا ورمز التحقق.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.verifyOtp(_email.text.trim(), _code.text.trim());
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = 'رمز غير صحيح أو منتهي، أو تعذر الاتصال بالخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'أدخل البريد الإلكتروني أولاً.');
      return;
    }
    setState(() { _error = null; _canResend = false; _resendTimer = 60; _startTimer(); });
    try {
      await _auth.resendOtp(_email.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل إعادة الإرسال. تحقق من الاتصال ثم حاول مجددًا.';
          _timer?.cancel();
          _canResend = true;
          _resendTimer = 0;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer <= 1) {
        t.cancel();
        if (mounted) setState(() { _canResend = true; _resendTimer = 0; });
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد البريد')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'رمز التحقق',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('تأكيد'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: (_canResend && !_loading) ? _resend : null,
              child: _resendTimer > 0
                  ? Text('إعادة الإرسال ($_resendTimer ثانية)')
                  : const Text('إعادة الإرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
