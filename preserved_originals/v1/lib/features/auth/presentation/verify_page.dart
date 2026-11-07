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
  void dispose() {
    _email.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.verifyOtp(_email.text.trim(), _code.text.trim());
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'رمز غير صحيح أو منتهي.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _error = null; _canResend = false; _resendTimer = 60; _startTimer(); });
    try {
      await _auth.resendOtp(_email.text.trim());
    } catch (e) {
      setState(() => _error = 'فشل إعادة الإرسال.');
      _timer?.cancel();
      _canResend = true;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer <= 1) {
        t.cancel();
        setState(() { _canResend = true; _resendTimer = 0; });
      } else {
        setState(() => _resendTimer--);
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
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
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
