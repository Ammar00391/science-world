import 'package:supabase_flutter/supabase_flutter.dart';

/// Public client configuration for the Science World Supabase project.
///
/// The publishable key is designed for client applications. Database access
/// must still be protected by Row Level Security (RLS) policies.
/// Never put a Supabase secret/service-role key in this file or in the APK.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://faiituujosrsthdrsefw.supabase.co',
  );

  // Keep the old define as a fallback so existing local build commands remain
  // compatible while Codemagic migrates to SUPABASE_PUBLISHABLE_KEY.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_oxs3N5EAiq7zfMH7_gPbgg_F3i6oerr',
    ),
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.startsWith('sb_publishable_');

  static Future<void> initialize() async {
    if (!isConfigured) {
      throw StateError(
        'Supabase غير مهيأ. تحقق من SUPABASE_URL وSUPABASE_PUBLISHABLE_KEY.',
      );
    }

    await Supabase.initialize(
      url: url,
      // supabase_flutter 2.x exposes the client key parameter as anonKey;
      // Supabase publishable keys are passed through this parameter.
      anonKey: publishableKey,
    );
  }
}
