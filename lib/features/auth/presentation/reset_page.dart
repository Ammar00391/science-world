import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import 'auth_mascot.dart';
import 'auth_support_button.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _email = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _message;
  AuthMascotMood _mascotMood = AuthMascotMood.facepalm;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(_email.text.trim())) {
      setState(() {
        _message = 'أدخل بريدًا إلكترونيًا صحيحًا.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _mascotMood = AuthMascotMood.thinking;
    });
    try {
      await _auth.resetPassword(_email.text.trim());
      if (mounted) {
        setState(() {
          _message = 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.';
          _mascotMood = AuthMascotMood.happy;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'تعذر الإرسال. تحقق من البريد والاتصال ثم حاول مجددًا.';
          _mascotMood = AuthMascotMood.sad;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعادة تعيين كلمة المرور')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const AuthSupportButton(),
            const SizedBox(height: 6),
            AuthMascot(mood: _mascotMood),
            const SizedBox(height: 8),
            const Text(
              'ولا يهمك، سنساعدك على استعادة حسابك',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF536985), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              onChanged: (_) => setState(() {
                _message = null;
                _mascotMood = AuthMascotMood.thinking;
              }),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mascotMood == AuthMascotMood.happy
                      ? Colors.green.shade700
                      : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إرسال رابط الاستعادة'),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('العودة إلى تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}
