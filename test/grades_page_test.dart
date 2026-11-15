import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:science_world/features/grades/presentation/grades_page.dart';

void main() {
  testWidgets('available baccalaureate grade opens its curriculum',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const GradesPage()),
        GoRoute(
          path: '/subjects',
          builder: (_, __) => const Scaffold(body: Text('curriculum page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('البكالوريا العلمي'));
    await tester.pumpAndSettle();

    expect(find.text('curriculum page'), findsOneWidget);
  });

  testWidgets('grade without catalog content is not selectable',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const GradesPage()),
        GoRoute(
          path: '/subjects',
          builder: (_, __) => const Scaffold(body: Text('curriculum page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final ninthGradeTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('التاسع'),
        matching: find.byType(ListTile),
      ),
    );
    expect(ninthGradeTile.onTap, isNull);
    expect(find.text('المحتوى قيد الإعداد'), findsNWidgets(3));
  });
}
