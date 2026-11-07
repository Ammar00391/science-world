import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import 'auth_mascot.dart';
import 'auth_support_button.dart';

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
  AuthMascotMood _mascotMood = AuthMascotMood.thinking;

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

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  Future<void> _verify() async {
    if (!_isValidEmail(_email.text) ||
        !RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() {
        _error = 'أدخل بريدًا صحيحًا ورمز تحقق مكوّنًا من 6 أرقام.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _mascotMood = AuthMascotMood.focused;
    });
    try {
      await _auth.verifyOtp(_email.text.trim(), _code.text.trim());
      if (mounted) {
        setState(() => _mascotMood = AuthMascotMood.celebrate);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/welcome');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'رمز غير صحيح أو منتهي، أو تعذر الاتصال بالخادم.';
          _mascotMood = AuthMascotMood.sad;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_isValidEmail(_email.text)) {
      setState(() {
        _error = 'أدخل بريدًا إلكترونيًا صحيحًا أولًا.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }

    setState(() {
      _error = null;
      _canResend = false;
      _resendTimer = 60;
      _mascotMood = AuthMascotMood.thinking;
    });
    _startTimer();
    try {
      await _auth.resendOtp(_email.text.trim());
      if (mounted) setState(() => _mascotMood = AuthMascotMood.happy);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'فشل إعادة الإرسال. تحقق من الاتصال ثم حاول مجددًا.';
          _timer?.cancel();
          _canResend = true;
          _resendTimer = 0;
          _mascotMood = AuthMascotMood.sad;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 1) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
        if (mounted) setState(() => _resendTimer = 0);
      } else if (mounted) {
        setState(() => _resendTimer--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد البريد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const AuthSupportButton(),
            const SizedBox(height: 8),
            AuthMascot(mood: _mascotMood),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              controller: _email,
              onChanged: (_) => setState(() {
                if (_error != null) _error = null;
                _mascotMood = AuthMascotMood.thinking;
              }),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              maxLength: 6,
              controller: _code,
              onChanged: (value) => setState(() {
                if (_error != null) _error = null;
                _mascotMood = value.length == 6
                    ? AuthMascotMood.focused
                    : AuthMascotMood.thinking;
              }),
              decoration: const InputDecoration(
                labelText: 'رمز التحقق',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
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
