import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_input_validator.dart';
import '../data/auth_service.dart';
import 'auth_support_button.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _recoveryMode = false;
  bool _showPassword = false;
  String? _message;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recoveryMode = GoRouterState.of(context).uri.queryParameters['mode'] == 'recovery';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();
    if (!AuthInputValidator.isValidEmail(_email.text)) {
      setState(() => _error = 'أدخل بريدًا إلكترونيًا صحيحًا.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await _auth.resetPassword(_email.text);
      if (mounted) {
        setState(() => _message = 'إذا كان البريد مسجلًا، فستصلك رسالة تحتوي على رابط آمن لتعيين كلمة مرور جديدة.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _auth.friendlyError(
            error,
            fallback: 'تعذر إرسال رسالة الاستعادة. تحقق من البريد وإعدادات SMTP في Supabase.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNewPassword() async {
    FocusScope.of(context).unfocus();
    if (!AuthInputValidator.isValidPassword(_password.text)) {
      setState(() => _error = 'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await _auth.updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح.')),
      );
      context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _auth.friendlyError(
            error,
            fallback: 'تعذر تحديث كلمة المرور. افتح أحدث رابط استعادة وصلك عبر البريد ثم حاول مجددًا.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recovery = _recoveryMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(recovery ? 'تعيين كلمة مرور جديدة' : 'استعادة كلمة المرور'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AuthSupportButton(),
            const SizedBox(height: 12),
            Icon(
              recovery ? Icons.lock_reset_rounded : Icons.mark_email_read_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              recovery ? 'اختر كلمة مرور جديدة' : 'سنرسل لك رابطًا آمنًا',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              recovery
                  ? 'أدخل كلمة مرور جديدة ثم أكدها لإكمال استعادة حسابك.'
                  : 'أدخل البريد المرتبط بحسابك، وسنرسل رسالة لإعادة تعيين كلمة المرور.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718096), height: 1.6),
            ),
            const SizedBox(height: 24),
            if (!recovery) ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              TextField(
                controller: _password,
                obscureText: !_showPassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : (recovery ? _saveNewPassword : _sendResetEmail),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(recovery ? 'حفظ كلمة المرور الجديدة' : 'إرسال رابط الاستعادة'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => context.go('/login'), child: const Text('العودة إلى تسجيل الدخول')),
          ],
        ),
      ),
    );
  }
}
