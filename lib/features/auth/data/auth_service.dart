import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import 'auth_input_validator.dart';

/// The single Supabase Auth entry point used by the application.
///
/// Only the public/publishable Supabase client is used here. Never add a
/// service-role or secret key to a Flutter application.
class AuthService {
  static const String authRedirectUri = 'scienceworld://login-callback/';
  static const String passwordRecoveryRedirectUri =
      'scienceworld://reset-password/';

  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    // Unit/widget tests can build the app before Supabase.initialize runs.
    // Treat that state as unavailable instead of throwing from a getter.
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured => _client != null;
  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (!AuthInputValidator.isValidEmail(normalizedEmail)) {
      throw ArgumentError('البريد الإلكتروني غير صالح.');
    }
    if (!AuthInputValidator.isValidFullName(normalizedName)) {
      throw ArgumentError('يرجى إدخال الاسم الكامل.');
    }
    if (!AuthInputValidator.isValidPhone(normalizedPhone)) {
      throw ArgumentError('رقم الهاتف غير صالح. استخدم مفتاح الدولة إن أمكن.');
    }
    if (!AuthInputValidator.isValidPassword(password)) {
      throw ArgumentError('كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.');
    }

    return client.auth.signUp(
      email: normalizedEmail,
      password: password,
      emailRedirectTo: authRedirectUri,
      data: {
        'full_name': normalizedName,
        'phone': normalizedPhone,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    if (!AuthInputValidator.isValidEmail(normalizedEmail)) {
      throw ArgumentError('البريد الإلكتروني غير صالح.');
    }
    if (password.isEmpty) {
      throw ArgumentError('يرجى إدخال كلمة المرور.');
    }
    return client.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    final client = _requireClient();
    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirectUri,
    );
    if (!launched) {
      throw StateError(
        'لم يتم فتح صفحة Google. تحقق من إعداد Google OAuth وروابط العودة في Supabase.',
      );
    }
    return true;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    if (!AuthInputValidator.isValidEmail(normalizedEmail)) {
      throw ArgumentError('البريد الإلكتروني غير صالح.');
    }
    await client.auth.resetPasswordForEmail(
      normalizedEmail,
      redirectTo: passwordRecoveryRedirectUri,
    );
  }

  /// Completes the password-recovery flow after the email link opens the app.
  Future<void> updatePassword(String newPassword) async {
    final client = _requireClient();
    if (!AuthInputValidator.isValidPassword(newPassword)) {
      throw ArgumentError('كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> verifyOtp(String email, String token) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedToken = token.trim();
    if (!AuthInputValidator.isValidEmail(normalizedEmail)) {
      throw ArgumentError('البريد الإلكتروني غير صالح.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedToken)) {
      throw ArgumentError('رمز التحقق يجب أن يتكون من 6 أرقام.');
    }
    await client.auth.verifyOTP(
      email: normalizedEmail,
      token: normalizedToken,
      type: OtpType.signup,
    );
  }

  Future<void> resendOtp(String email) async {
    final client = _requireClient();
    final normalizedEmail = email.trim().toLowerCase();
    if (!AuthInputValidator.isValidEmail(normalizedEmail)) {
      throw ArgumentError('البريد الإلكتروني غير صالح.');
    }
    await client.auth.resend(
      email: normalizedEmail,
      type: OtpType.signup,
    );
  }

  Future<void> updateDisplayName(String name) async {
    final client = _requireClient();
    if (!AuthInputValidator.isValidFullName(name)) {
      throw ArgumentError('الاسم يجب أن يتكون من حرفين على الأقل.');
    }
    final metadata = <String, dynamic>{
      ...?client.auth.currentUser?.userMetadata,
      'full_name': name.trim(),
    };
    await client.auth.updateUser(UserAttributes(data: metadata));
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'خدمة الحسابات غير مهيأة. تحقق من إعدادات Supabase.',
      );
    }
    return client;
  }

  /// Convert common backend responses into short, actionable Arabic messages.
  String friendlyError(Object error, {required String fallback}) {
    if (error is ArgumentError || error is StateError) {
      return error.toString().replaceFirst('Invalid argument(s): ', '');
    }
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('user already exists')) {
        return 'هذا البريد مسجل بالفعل. جرّب تسجيل الدخول أو استعادة كلمة المرور.';
      }
      if (message.contains('invalid login credentials')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (message.contains('email not confirmed')) {
        return 'يرجى تأكيد بريدك الإلكتروني أولًا.';
      }
      if (message.contains('password') &&
          (message.contains('weak') || message.contains('short'))) {
        return 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.';
      }
      if (message.contains('rate limit') || message.contains('too many')) {
        return 'تم تجاوز عدد المحاولات مؤقتًا. انتظر قليلًا ثم حاول مجددًا.';
      }
    }
    return fallback;
  }
}
