import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/screens/activation_screen.dart';

void main() {
  testWidgets(
    'legacy ActivationScreen opens the canonical activation page',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ActivationScreen()),
      );

      expect(find.text('تفعيل اشتراك Science World'), findsOneWidget);
      expect(find.text('تفعيل الاشتراك'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
