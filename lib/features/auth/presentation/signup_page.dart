import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import 'auth_mascot.dart';
import 'auth_support_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;
  AuthMascotMood _mascotMood = AuthMascotMood.shy;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  void _onPasswordChanged(String value) {
    setState(() {
      _error = null;
      _mascotMood = !_showPassword
          ? AuthMascotMood.shy
          : value.length >= 8
              ? AuthMascotMood.happy
              : AuthMascotMood.focused;
    });
  }

  Future<void> _submit() async {
    if (!_validEmail(_email.text)) {
      setState(() {
        _error = 'أدخل بريدًا إلكترونيًا صحيحًا.';
        _mascotMood = AuthMascotMood.sad;
      });
      return;
    }
    if (_pass.text.length < 8) {
      setState(() {
        _error = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
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
      await _auth.signUp(_email.text.trim(), _pass.text);
      if (mounted) {
        setState(() => _mascotMood = AuthMascotMood.celebrate);
        await Future<void>.delayed(const Duration(milliseconds: 550));
        if (mounted) {
          context.go('/verify?email=${Uri.encodeComponent(_email.text.trim())}');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر إنشاء الحساب. تحقق من الاتصال وإعدادات البريد.';
          _mascotMood = AuthMascotMood.sad;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              const AuthSupportButton(),
              const SizedBox(height: 8),
              const Icon(Icons.auto_awesome_rounded,
                  size: 48, color: Color(0xFF2878E8)),
              const SizedBox(height: 5),
              const Text(
                'أنشئ حسابك',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A4C)),
              ),
              const SizedBox(height: 4),
              const Text(
                'خطوة واحدة لتبدأ رحلتك في عالم العلوم',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718096)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onChanged: (_) => setState(() {
                  _error = null;
                  if (_mascotMood != AuthMascotMood.celebrate &&
                      _mascotMood != AuthMascotMood.sad) {
                    _mascotMood = AuthMascotMood.thinking;
                  }
                }),
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pass,
                      obscureText: !_showPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: _onPasswordChanged,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور (8 أحرف على الأقل)',
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
                  ),
                  const SizedBox(width: 8),
                  AuthMascot(
                    mood: _mascotMood,
                    passwordVisible: _showPassword,
                    compact: true,
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء الحساب'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('لديك حساب؟ تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
}
