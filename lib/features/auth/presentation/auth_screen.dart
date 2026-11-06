import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_input_validator.dart';
import '../data/auth_service.dart';
import 'auth_support_button.dart';

/// Combined sign-in/sign-up entry point. The existing dedicated routes remain
/// available for deep links and backward compatibility.
class AuthScreen extends StatefulWidget {
  final int initialTab;

  const AuthScreen({super.key, this.initialTab = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  String? _error;
  int _activeTab = 0;

  bool get _isSignUp => _activeTab == 1;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 1 ? 1 : 0;
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeTab,
    );
    _tabs.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabs.indexIsChanging) return;
    if (_activeTab != _tabs.index && mounted) {
      setState(() {
        _activeTab = _tabs.index;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChange);
    _tabs.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE5F0)),
        ),
      );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        final response = await _auth.signUp(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
          phone: _phone.text,
        );
        if (!mounted) return;
        if (response.session != null) {
          context.go('/welcome');
        } else {
          final email = Uri.encodeComponent(_email.text.trim().toLowerCase());
          context.go('/verify?email=$email');
        }
      } else {
        await _auth.signIn(email: _email.text, password: _password.text);
        if (mounted) context.go('/welcome?returning=1');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _auth.friendlyError(
            error,
            fallback: _isSignUp
                ? 'تعذر إنشاء الحساب. تحقق من البيانات وإعدادات البريد في Supabase.'
                : 'تعذر تسجيل الدخول. تحقق من البريد وكلمة المرور وتأكيد البريد الإلكتروني.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
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
            fallback: 'تعذر بدء تسجيل Google. تحقق من إعداد OAuth في Supabase.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: [
                const AuthSupportButton(),
                const SizedBox(height: 18),
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D85F5), Color(0xFF124EAB)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2878E8).withOpacity(.22),
                        blurRadius: 24,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Colors.white,
                    size: 43,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Science World',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A4C),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'بوابتك إلى التعلم والفهم والتفوّق',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF718096)),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    onTap: (index) {
                      setState(() {
                        _activeTab = index;
                        _error = null;
                      });
                    },
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120E2F55),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF1769E8),
                    unselectedLabelColor: const Color(0xFF718096),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: const [
                      Tab(text: 'تسجيل الدخول'),
                      Tab(text: 'إنشاء حساب'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _isSignUp
                            ? Column(
                                key: const ValueKey('signup-fields'),
                                children: [
                                  TextFormField(
                                    controller: _name,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: _decoration(
                                      'الاسم الكامل',
                                      Icons.person_outline,
                                    ),
                                    validator: (value) =>
                                        AuthInputValidator.isValidFullName(value ?? '')
                                            ? null
                                            : 'يرجى إدخال الاسم الكامل.',
                                  ),
                                  const SizedBox(height: 13),
                                  TextFormField(
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.telephoneNumber],
                                    decoration: _decoration(
                                      'رقم الهاتف مع مفتاح الدولة',
                                      Icons.phone_outlined,
                                    ),
                                    validator: (value) =>
                                        AuthInputValidator.isValidPhone(value ?? '')
                                            ? null
                                            : 'أدخل رقم هاتف صحيحًا مع مفتاح الدولة.',
                                  ),
                                  const SizedBox(height: 13),
                                ],
                              )
                            : const SizedBox.shrink(key: ValueKey('login-fields')),
                      ),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: _decoration(
                          'البريد الإلكتروني',
                          Icons.email_outlined,
                        ),
                        validator: (value) =>
                            AuthInputValidator.isValidEmail(value ?? '')
                                ? null
                                : 'أدخل بريدًا إلكترونيًا صحيحًا.',
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: _isSignUp
                            ? TextInputAction.next
                            : TextInputAction.done,
                        autofillHints: [
                          _isSignUp
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: _decoration(
                          _isSignUp
                              ? 'كلمة المرور (8 أحرف على الأقل)'
                              : 'كلمة المرور',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _showPassword = !_showPassword,
                            ),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (_isSignUp &&
                              !AuthInputValidator.isValidPassword(password)) {
                            return 'استخدم 8 أحرف على الأقل.';
                          }
                          if (!_isSignUp && password.isEmpty) {
                            return 'يرجى إدخال كلمة المرور.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!_isSignUp && !_loading) _submit();
                        },
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: !_showConfirmation,
                          textInputAction: TextInputAction.done,
                          decoration: _decoration(
                            'تأكيد كلمة المرور',
                            Icons.lock_reset_outlined,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _showConfirmation = !_showConfirmation,
                              ),
                              icon: Icon(
                                _showConfirmation
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (value) => value == _password.text
                              ? null
                              : 'كلمتا المرور غير متطابقتين.',
                          onFieldSubmitted: (_) {
                            if (!_loading) _submit();
                          },
                        ),
                      ],
                      if (!_isSignUp)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => context.push('/reset'),
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: (_loading || _googleLoading) ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isSignUp ? 'إنشاء الحساب' : 'تسجيل الدخول'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: (_loading || _googleLoading)
                            ? null
                            : _continueWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: Text(
                          _googleLoading
                              ? 'جارٍ الاتصال بـ Google...'
                              : 'المتابعة باستخدام Google',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSignUp
                            ? 'بإنشاء الحساب، سيتم حفظ بياناتك الأساسية في ملفك الشخصي.'
                            : 'بتسجيل الدخول يمكنك متابعة الدروس والاختبارات وحفظ تقدمك.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8794A6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
