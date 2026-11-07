import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ScienceWorldApp extends StatefulWidget {
  const ScienceWorldApp({super.key});

  @override
  State<ScienceWorldApp> createState() => _ScienceWorldAppState();
}

class _ScienceWorldAppState extends State<ScienceWorldApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isInitialized) {
      try {
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (state) {
            if (state.event == AuthChangeEvent.passwordRecovery) {
              appRouter.go('/update-password');
            }
          },
        );
      } catch (_) {
        // Offline/uninitialized Supabase must not block the local app shell.
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'عالم العلوم | Science World',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(
          textDirection: Localizations.localeOf(context).languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
