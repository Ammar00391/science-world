import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the optional legacy subjects/units/lessons tables from Supabase.
///
/// The active V21/V22 schema may use a local curriculum catalog instead.
/// This service is used only when a subject row came from the Supabase table.
class CurriculumService {
  CurriculumService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches the units belonging to a single subject.
  ///
  /// Supports both `unit_order` and the older `order_index` column. If neither
  /// exists, rows are still returned and the screen displays them normally.
  Future<List<Map<String, dynamic>>> getUnitsForSubject(
    String subjectId,
  ) async {
    final id = subjectId.trim();
    if (id.isEmpty) {
      throw ArgumentError('معرّف المادة غير صالح.');
    }

    return _fetchChildren(
      table: 'units',
      foreignKey: 'subject_id',
      parentId: id,
      orderColumns: const ['unit_order', 'order_index', 'created_at'],
    );
  }

  /// Fetches lessons belonging to a unit, in their configured order.
  Future<List<Map<String, dynamic>>> getLessonsForUnit(String unitId) async {
    final id = unitId.trim();
    if (id.isEmpty) {
      throw ArgumentError('معرّف الوحدة غير صالح.');
    }

    return _fetchChildren(
      table: 'lessons',
      foreignKey: 'unit_id',
      parentId: id,
      orderColumns: const ['lesson_order', 'order_index', 'created_at'],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchChildren({
    required String table,
    required String foreignKey,
    required String parentId,
    required List<String> orderColumns,
  }) async {
    Object? lastError;

    // Try known ordering columns in order of preference. A missing optional
    // column should not prevent loading valid rows from older deployments.
    for (final orderColumn in orderColumns) {
      try {
        final response = await _supabase
            .from(table)
            .select()
            .eq(foreignKey, parentId)
            .order(orderColumn, ascending: true);
        return _toRows(response);
      } catch (error) {
        lastError = error;
      }
    }

    // Last compatibility attempt: query without relying on an ordering column.
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(foreignKey, parentId);
      return _toRows(response);
    } catch (error) {
      throw StateError(
        'تعذر تحميل بيانات جدول $table من Supabase. '
        'تحقق من وجود الجدول وعمود $foreignKey وسياسة القراءة RLS. '
        'التفاصيل: $error (آخر خطأ ترتيب: $lastError)',
      );
    }
  }

  List<Map<String, dynamic>> _toRows(dynamic response) {
    if (response is! List) return <Map<String, dynamic>>[];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
