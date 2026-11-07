import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A missing/misconfigured backend must not prevent local/offline screens
  // from opening. Auth and online services already guard their own clients.
  try {
    await SupabaseConfig.initialize();
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ProviderScope(child: ScienceWorldApp()));
}
