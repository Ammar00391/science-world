import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:science_world/features/splash/presentation/splash_page.dart';

void main() {
  testWidgets('splash skip navigates directly to the intro page',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(
          path: '/intro',
          builder: (_, __) => const Scaffold(body: Text('intro page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('intro page'), findsOneWidget);
  });

  testWidgets('splash displays the official tagline with reduced motion',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(
          path: '/intro',
          builder: (_, __) => const Scaffold(body: Text('intro page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('اكتشف، تعلّم، تطوّر'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
