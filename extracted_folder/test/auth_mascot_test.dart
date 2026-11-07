import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/auth/presentation/auth_mascot.dart';

void main() {
  testWidgets('authentication mascot animates and changes its expression',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AuthMascot(mood: AuthMascotMood.thinking),
      ),
    ));
    expect(find.text('أفكر… أين وصلنا؟'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AuthMascot(mood: AuthMascotMood.celebrate),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('نجحنا! أهلًا بك 💙'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact signup mascot fits beside the password field',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: AuthMascot(
            mood: AuthMascotMood.shy,
            passwordVisible: false,
            compact: true,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
