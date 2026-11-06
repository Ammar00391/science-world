import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../features/auth/data/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ScienceWorldApp extends StatelessWidget {
  const ScienceWorldApp({super.key});

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
        return _AuthEventHandler(
          child: Directionality(
            textDirection: Localizations.localeOf(context).languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Handles auth redirects that return to the app from email links.
/// Password-recovery links open the new-password form; confirmation/OAuth
/// callbacks that sign in while the user is on an auth screen continue to the
/// welcome page.
class _AuthEventHandler extends StatefulWidget {
  const _AuthEventHandler({required this.child});

  final Widget child;

  @override
  State<_AuthEventHandler> createState() => _AuthEventHandlerState();
}

class _AuthEventHandlerState extends State<_AuthEventHandler> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isConfigured) {
      _subscription = AuthService().authStateChanges.listen(_handleAuthState);
    }
  }

  void _handleAuthState(AuthState state) {
    if (!mounted) return;
    if (state.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) appRouter.go('/reset?mode=recovery');
      });
      return;
    }

    if (state.event == AuthChangeEvent.signedIn) {
      final currentPath = appRouter.routeInformationProvider.value.uri.path;
      if (currentPath == '/auth' ||
          currentPath == '/login' ||
          currentPath == '/signup' ||
          currentPath == '/verify' ||
          currentPath == '/intro') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) appRouter.go('/welcome?returning=1');
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
