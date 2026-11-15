import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/app/theme/app_theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final controller = AppThemeController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await controller.load();
  });

  test('persists and restores the selected theme mode', () async {
    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);

    await controller.load();
    expect(controller.mode, ThemeMode.dark);

    await controller.setMode(ThemeMode.light);
    expect(controller.mode, ThemeMode.light);
  });

  test('persists and restores the reduced-motion preference', () async {
    await controller.setReduceMotion(true);
    expect(controller.reduceMotion, isTrue);

    await controller.load();
    expect(controller.reduceMotion, isTrue);

    await controller.setReduceMotion(false);
    expect(controller.reduceMotion, isFalse);
  });
}
