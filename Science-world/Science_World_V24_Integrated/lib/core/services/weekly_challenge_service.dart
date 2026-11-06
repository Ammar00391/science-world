import 'package:shared_preferences/shared_preferences.dart';

/// Device-local weekly challenge points. The active competition resets each Monday;
/// lifetime XP remains untouched. Cloud leaderboards require the SQL migration and
/// server-validated scoring before being enabled for real competition.
class WeeklyChallengeService {
  static const _weekKey = 'sw_weekly_points_period_v1';
  static const _pointsKey = 'sw_weekly_points_value_v1';

  String _periodKey([DateTime? value]) {
    final now = value ?? DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - DateTime.monday));
    return '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  Future<int> points() async {
    final prefs = await SharedPreferences.getInstance();
    final period = _periodKey();
    if (prefs.getString(_weekKey) != period) {
      await prefs.setString(_weekKey, period);
      await prefs.setInt(_pointsKey, 0);
      return 0;
    }
    return prefs.getInt(_pointsKey) ?? 0;
  }

  Future<int> addPoints(int amount) async {
    if (amount <= 0) return points();
    final prefs = await SharedPreferences.getInstance();
    final period = _periodKey();
    if (prefs.getString(_weekKey) != period) {
      await prefs.setString(_weekKey, period);
      await prefs.setInt(_pointsKey, 0);
    }
    final updated = (prefs.getInt(_pointsKey) ?? 0) + amount;
    await prefs.setInt(_pointsKey, updated);
    return updated;
  }
}
