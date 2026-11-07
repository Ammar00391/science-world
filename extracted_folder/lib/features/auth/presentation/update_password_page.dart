import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import 'auth_mascot.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _showPassword = false;
  String? _message;
  AuthMascotMood _mascotMood = AuthMascotMood.thinking;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 8) {
      setState(() {
        _message = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() {
        _message = 'كلمتا المرور غير متطابقتين.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _mascotMood = AuthMascotMood.focused;
    });
    try {
      await _auth.updatePassword(_password.text);
      if (mounted) {
        setState(() => _mascotMood = AuthMascotMood.celebrate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح.')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 550));
        if (mounted) context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'تعذر تحديث كلمة المرور. افتح رابط الاستعادة الجديد وحاول مرة أخرى.';
          _mascotMood = AuthMascotMood.sad;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _message = null;
      _mascotMood = value.length >= 8
          ? AuthMascotMood.happy
          : AuthMascotMood.focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعيين كلمة مرور جديدة')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AuthMascot(mood: _mascotMood, passwordVisible: _showPassword),
            const SizedBox(height: 8),
            const Text(
              'اختر كلمة مرور جديدة لحسابك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: _onPasswordChanged,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() {
                    _showPassword = !_showPassword;
                    _mascotMood = _showPassword
                        ? AuthMascotMood.focused
                        : AuthMascotMood.shy;
                  }),
                  icon: Icon(_showPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmation,
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: (_) => setState(() {
                if (_confirmation.text.isNotEmpty &&
                    _password.text != _confirmation.text) {
                  _mascotMood = AuthMascotMood.thinking;
                } else if (_password.text.length >= 8) {
                  _mascotMood = AuthMascotMood.happy;
                }
              }),
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ كلمة المرور'),
            ),
          ],
        ),
      ),
    );
  }
}
