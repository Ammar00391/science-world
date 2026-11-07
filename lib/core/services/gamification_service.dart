import 'package:shared_preferences/shared_preferences.dart';

class GamificationSnapshot {
  final int xp;
  final int correctAnswers;
  final int streak;
  final String lastStudyDay;
  final Set<String> achievements;
  const GamificationSnapshot({required this.xp, required this.correctAnswers, required this.streak, required this.lastStudyDay, required this.achievements});
  int get level => (xp ~/ 100) + 1;
  int get xpInLevel => xp % 100;
  double get levelProgress => xpInLevel / 100;
}

/// Local-first student progress. It stores only device-local progress; cloud sync can be added separately.
class GamificationService {
  static const _xpKey = 'sw_gamification_xp_v1';
  static const _correctKey = 'sw_gamification_correct_v1';
  static const _streakKey = 'sw_gamification_streak_v1';
  static const _lastDayKey = 'sw_gamification_last_day_v1';
  static const _achievementsKey = 'sw_gamification_achievements_v1';

  String _dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Future<GamificationSnapshot> load() async {
    final p = await SharedPreferences.getInstance();
    return GamificationSnapshot(
      xp: p.getInt(_xpKey) ?? 0,
      correctAnswers: p.getInt(_correctKey) ?? 0,
      streak: p.getInt(_streakKey) ?? 0,
      lastStudyDay: p.getString(_lastDayKey) ?? '',
      achievements: (p.getStringList(_achievementsKey) ?? <String>[]).toSet(),
    );
  }

  Future<GamificationSnapshot> recordCorrectAnswer({int xp = 10}) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_xpKey, (p.getInt(_xpKey) ?? 0) + xp);
    await p.setInt(_correctKey, (p.getInt(_correctKey) ?? 0) + 1);
    await _updateStudyDay(p);
    await _unlockMilestones(p);
    return load();
  }

  Future<GamificationSnapshot> recordStudySession() async {
    final p = await SharedPreferences.getInstance();
    await _updateStudyDay(p);
    await _unlockMilestones(p);
    return load();
  }

  Future<void> _updateStudyDay(SharedPreferences p) async {
    final today = _dayKey(DateTime.now());
    final last = p.getString(_lastDayKey) ?? '';
    if (last == today) return;
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final streak = p.getInt(_streakKey) ?? 0;
    await p.setInt(_streakKey, last == yesterday ? streak + 1 : 1);
    await p.setString(_lastDayKey, today);
  }

  Future<void> _unlockMilestones(SharedPreferences p) async {
    final xp = p.getInt(_xpKey) ?? 0;
    final correct = p.getInt(_correctKey) ?? 0;
    final streak = p.getInt(_streakKey) ?? 0;
    final unlocked = (p.getStringList(_achievementsKey) ?? <String>[]).toSet();
    if (correct >= 1) unlocked.add('first_answer');
    if (correct >= 10) unlocked.add('ten_answers');
    if (xp >= 100) unlocked.add('level_two');
    if (streak >= 3) unlocked.add('three_day_streak');
    if (streak >= 7) unlocked.add('seven_day_streak');
    await p.setStringList(_achievementsKey, unlocked.toList());
  }

  Future<void> resetLocalProgress() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [_xpKey, _correctKey, _streakKey, _lastDayKey, _achievementsKey]) { await p.remove(k); }
  }
}
