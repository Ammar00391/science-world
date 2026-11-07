import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/app/app.dart';

void main() {
  testWidgets('App renders splash', (tester) async {
    await tester.pumpWidget(const ScienceWorldApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}