import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores a small, private history on this device. It is not cloud sync.
class LocalExamAttemptStore {
  static const String _storageKey = 'science_world_local_exam_attempts_v1';
  static const int _maxRecords = 60;

  Future<void> save(Map<String, dynamic> record) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final existing = (await load()).toList(growable: true);
      existing.insert(0, Map<String, dynamic>.from(record));
      final limited = existing.take(_maxRecords).toList(growable: false);
      await preferences.setString(_storageKey, jsonEncode(limited));
    } catch (_) {
      // A local history failure must never block the student from seeing a result.
    }
  }

  Future<List<Map<String, dynamic>>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: true);
    } catch (_) {
      return const [];
    }
  }
}
