import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';

class ScienceWorldApp extends StatefulWidget {
  const ScienceWorldApp({super.key});

  @override
  State<ScienceWorldApp> createState() => _ScienceWorldAppState();
}

class _ScienceWorldAppState extends State<ScienceWorldApp> {
  StreamSubscription<AuthState>? _authSubscription;
  final _themeController = AppThemeController.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_loadThemeMode());
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

  Future<void> _loadThemeMode() async {
    try {
      await _themeController.load();
    } catch (error, stackTrace) {
      debugPrint('Theme preference unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => MaterialApp.router(
        title: 'عالم العلوم | Science World',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeController.mode,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return Directionality(
            textDirection: Localizations.localeOf(context).languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: mediaQuery.copyWith(
                disableAnimations:
                    mediaQuery.disableAnimations || _themeController.reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
