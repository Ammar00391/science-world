import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _preferenceKey = 'science_world_dark_mode';
  static const _reduceMotionKey = 'science_world_reduce_motion';

  ThemeMode _mode = ThemeMode.light;
  bool _reduceMotion = false;
  ThemeMode get mode => _mode;
  bool get reduceMotion => _reduceMotion;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _mode = preferences.getBool(_preferenceKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
    _reduceMotion = preferences.getBool(_reduceMotionKey) == true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      throw ArgumentError.value(mode, 'mode', 'Only light and dark modes are supported.');
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_preferenceKey, mode == ThemeMode.dark);
    if (!saved) throw StateError('تعذر حفظ إعداد المظهر.');
    _mode = mode;
    notifyListeners();
  }

  Future<void> setReduceMotion(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_reduceMotionKey, enabled);
    if (!saved) throw StateError('تعذر حفظ إعداد تقليل الحركة.');
    _reduceMotion = enabled;
    notifyListeners();
  }
}
