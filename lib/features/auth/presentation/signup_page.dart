import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_input_validator.dart';
import '../data/auth_service.dart';
import 'auth_support_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _googleLoading = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _auth.signUp(
        email: _email.text,
        password: _password.text,
        fullName: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;

      final email = Uri.encodeComponent(_email.text.trim().toLowerCase());
      if (response.session != null) {
        context.go('/welcome');
      } else {
        context.go('/verify?email=$email');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _auth.friendlyError(
            error,
            fallback: 'تعذر إنشاء الحساب. تحقق من البيانات واتصال الإنترنت وإعدادات البريد في Supabase.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _auth.friendlyError(
            error,
            fallback: 'تعذر بدء التسجيل باستخدام Google. تحقق من إعداد OAuth في Supabase.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              const AuthSupportButton(),
              const SizedBox(height: 8),
              const Icon(Icons.science_rounded, size: 58, color: Color(0xFF2878E8)),
              const SizedBox(height: 10),
              Text(
                'مرحبًا بك في عالم العلوم',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF102A4C),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'أنشئ حسابك واحفظ تقدمك ونتائجك التعليمية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718096)),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                autofillHints: const [AutofillHints.name],
                decoration: _decoration('الاسم الكامل', Icons.person_outline),
                validator: (value) => AuthInputValidator.isValidFullName(value ?? '')
                    ? null
                    : 'أدخل اسمًا لا يقل عن حرفين.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+().\s-]')),
                  LengthLimitingTextInputFormatter(22),
                ],
                decoration: _decoration('رقم الهاتف مع مفتاح الدولة', Icons.phone_outlined),
                validator: (value) => AuthInputValidator.isValidPhone(value ?? '')
                    ? null
                    : 'أدخل رقم هاتف صحيحًا، مثل +90 538 956 7265.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: _decoration('البريد الإلكتروني', Icons.email_outlined),
                validator: (value) => AuthInputValidator.isValidEmail(value ?? '')
                    ? null
                    : 'أدخل بريدًا إلكترونيًا صحيحًا.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _decoration('كلمة المرور (8 أحرف على الأقل)', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (value) => AuthInputValidator.isValidPassword(value ?? '')
                    ? null
                    : 'استخدم 8 أحرف على الأقل.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPassword,
                obscureText: !_showConfirmation,
                textInputAction: TextInputAction.done,
                decoration: _decoration('تأكيد كلمة المرور', Icons.lock_reset_outlined).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showConfirmation = !_showConfirmation),
                    icon: Icon(_showConfirmation ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (value) => value == _password.text
                    ? null
                    : 'كلمتا المرور غير متطابقتين.',
                onFieldSubmitted: (_) {
                  if (!_loading) _submit();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إنشاء الحساب'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (_loading || _googleLoading) ? null : _signUpWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: Text(_googleLoading ? 'جارٍ فتح Google...' : 'المتابعة باستخدام Google'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/auth'),
                child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
              ),
              const SizedBox(height: 8),
              const Text(
                'بإنشاء الحساب، سيتم حفظ بياناتك الأساسية في حسابك وملفك الشخصي.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF8794A6), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
