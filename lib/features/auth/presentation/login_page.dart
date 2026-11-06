
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_input_validator.dart';
import '../data/auth_service.dart';
import 'auth_support_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _loading = false, _showPassword = false, _googleLoading = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!AuthInputValidator.isValidEmail(_email.text) || _pass.text.isEmpty) {
      setState(() => _error = 'أدخل بريدًا إلكترونيًا صحيحًا وكلمة المرور.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signIn(email: _email.text, password: _pass.text);
      if (mounted) context.go('/welcome?returning=1');
    } catch (error) {
      if (mounted) setState(() => _error = _auth.friendlyError(
        error,
        fallback: 'تعذر تسجيل الدخول. تحقق من بياناتك واتصالك، وتأكد من تأكيد البريد الإلكتروني.',
      ));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _google() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      await _auth.signInWithGoogle();
    } catch (error) {
      if (mounted) setState(() => _error = _auth.friendlyError(
        error,
        fallback: 'تعذر بدء تسجيل Google. تأكد من إعداد Google في Supabase.',
      ));
    } finally { if (mounted) setState(() => _googleLoading = false); }
  }

  void _guestInfo() => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2878E8), size: 34),
    title: const Text('التصفح كضيف'),
    content: const Text('يمكنك الدخول كضيف للتعرّف على التطبيق، لكن استخدام الدروس والكتب والأسئلة والمساعد يتطلب إنشاء حساب أو تسجيل الدخول.'),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا')),
      FilledButton(onPressed: () { Navigator.pop(ctx); context.go('/auth?tab=signup'); }, child: const Text('إنشاء حساب'))],
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(22, 12, 22, 28), children: [
      const AuthSupportButton(),
      const SizedBox(height: 12),
      const Icon(Icons.science_rounded, size: 58, color: Color(0xFF2878E8)),
      const SizedBox(height: 12),
      const Text('أهلًا بعودتك', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF102A4C))),
      const SizedBox(height: 6),
      const Text('سجّل دخولك لمتابعة رحلتك التعليمية', textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF718096))),
      const SizedBox(height: 28),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false,
        decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 14),
      TextField(controller: _pass, obscureText: !_showPassword,
        decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility)))),
      Align(alignment: Alignment.centerLeft, child: TextButton(
        onPressed: () => context.go('/reset'), child: const Text('نسيت كلمة المرور؟'))),
      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
      SizedBox(height: 52, child: ElevatedButton(onPressed: _loading ? null : _submit,
        child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول'))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _googleLoading ? null : _google,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
        label: Text(_googleLoading ? 'جارٍ الاتصال...' : 'المتابعة باستخدام Google')),
      const SizedBox(height: 12),
      TextButton(onPressed: () => context.go('/auth?tab=signup'), child: const Text('ليس لديك حساب؟ أنشئ حسابًا')),
      const Divider(height: 28),
      OutlinedButton.icon(onPressed: _guestInfo,
        icon: const Icon(Icons.person_outline_rounded), label: const Text('الدخول كضيف')),
      const SizedBox(height: 8),
      const Text('الدخول كضيف لا يتيح استخدام المحتوى التعليمي؛ يلزم حساب للمتابعة.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF8794A6))),
    ])),
  );
}
