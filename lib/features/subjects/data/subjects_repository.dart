import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../curriculum/data/curriculum_repository.dart';

class SubjectEntry {
  final String? id;
  final String name;
  final String? description;
  final int? unitCount;
  final int? lessonCount;
  final bool fromSupabase;

  const SubjectEntry({
    required this.name,
    this.id,
    this.description,
    this.unitCount,
    this.lessonCount,
    this.fromSupabase = false,
  });
}

class SubjectsCatalog {
  final String schoolYear;
  final String curriculumBasis;
  final List<SubjectEntry> subjects;
  final bool fromSupabase;
  final String? notice;

  const SubjectsCatalog({
    required this.schoolYear,
    required this.curriculumBasis,
    required this.subjects,
    required this.fromSupabase,
    this.notice,
  });
}

/// Loads database subjects when the legacy content tables are available, and
/// falls back to the reviewed in-app curriculum catalog for offline use.
///
/// The canonical V21/V22 schema does not create a `subjects` table; some
/// existing deployments may have the older subjects/units/lessons tables.
/// This adapter supports both without making the main learning catalog depend
/// on an optional legacy table.
class SubjectsRepository {
  final CurriculumRepository _curriculum = CurriculumRepository();

  Future<SubjectsCatalog> load() async {
    final local = await _curriculum.loadCatalog();
    final localByName = <String, CurriculumSubject>{
      for (final subject in local.subjects) subject.name.trim(): subject,
    };

    if (SupabaseConfig.isConfigured) {
      try {
        final response = await Supabase.instance.client.from('subjects').select();
        final rows = response.whereType<Map>().map(
          (row) => Map<String, dynamic>.from(row),
        );

        final remoteSubjects = rows
            .map((row) {
              final name = (row['title'] ?? row['name'] ?? '')
                  .toString()
                  .trim();
              if (name.isEmpty) return null;

              final matchingLocal = localByName[name];
              final description = (row['description'] ?? '').toString().trim();

              return SubjectEntry(
                id: row['id']?.toString(),
                name: name,
                description: description.isEmpty ? null : description,
                unitCount: matchingLocal?.units.length,
                lessonCount: matchingLocal?.lessonCount,
                fromSupabase: true,
              );
            })
            .whereType<SubjectEntry>()
            .toList(growable: false);

        if (remoteSubjects.isNotEmpty) {
          return SubjectsCatalog(
            schoolYear: local.schoolYear,
            curriculumBasis: local.curriculumBasis,
            subjects: remoteSubjects,
            fromSupabase: true,
          );
        }

        return _fromLocal(
          local,
          notice: 'جدول المواد في Supabase فارغ حاليًا؛ نعرض فهرس المناهج المدمج.',
        );
      } catch (_) {
        return _fromLocal(
          local,
          notice: 'تعذر قراءة جدول subjects؛ نعرض فهرس المناهج المدمج مؤقتًا.',
        );
      }
    }

    return _fromLocal(
      local,
      notice: 'Supabase غير مهيأ؛ نعرض فهرس المناهج المتاح داخل التطبيق.',
    );
  }

  SubjectsCatalog _fromLocal(
    CurriculumCatalog local, {
    required String notice,
  }) {
    return SubjectsCatalog(
      schoolYear: local.schoolYear,
      curriculumBasis: local.curriculumBasis,
      fromSupabase: false,
      notice: notice,
      subjects: local.subjects
          .map(
            (subject) => SubjectEntry(
              name: subject.name,
              description: null,
              unitCount: subject.units.length,
              lessonCount: subject.lessonCount,
            ),
          )
          .toList(growable: false),
    );
  }
}
