import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class CurriculumLesson {
  final String name;
  final List<String> subtopics;
  final Map<String, dynamic> learningComponents;

  const CurriculumLesson({
    required this.name,
    this.subtopics = const [],
    this.learningComponents = const {},
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> json) {
    final rawSubtopics = json['subtopics'];
    final rawComponents = json['learning_components'];
    return CurriculumLesson(
      name: (json['name'] ?? '').toString().trim(),
      subtopics: rawSubtopics is List
          ? rawSubtopics.map((item) => item.toString()).toList(growable: false)
          : const [],
      learningComponents: rawComponents is Map
          ? Map<String, dynamic>.from(rawComponents)
          : const {},
    );
  }
}

class CurriculumUnit {
  final String name;
  final List<CurriculumLesson> lessons;

  const CurriculumUnit({required this.name, required this.lessons});

  factory CurriculumUnit.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    return CurriculumUnit(
      name: (json['name'] ?? '').toString().trim(),
      lessons: rawLessons is List
          ? rawLessons
              .whereType<Map>()
              .map((item) => CurriculumLesson.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((lesson) => lesson.name.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class CurriculumSubject {
  final String name;
  final String category;
  final List<CurriculumUnit> units;

  const CurriculumSubject({
    required this.name,
    required this.category,
    required this.units,
  });

  int get lessonCount =>
      units.fold<int>(0, (total, unit) => total + unit.lessons.length);

  factory CurriculumSubject.fromJson(Map<String, dynamic> json) {
    final rawUnits = json['units'];
    return CurriculumSubject(
      name: (json['name'] ?? '').toString().trim(),
      category: (json['category'] ?? 'core').toString(),
      units: rawUnits is List
          ? rawUnits
              .whereType<Map>()
              .map((item) => CurriculumUnit.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((unit) => unit.name.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class CurriculumCatalog {
  final String schoolYear;
  final String curriculumBasis;
  final String status;
  final List<CurriculumSubject> subjects;

  const CurriculumCatalog({
    required this.schoolYear,
    required this.curriculumBasis,
    required this.status,
    required this.subjects,
  });

  factory CurriculumCatalog.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'];
    return CurriculumCatalog(
      schoolYear: (json['school_year'] ?? '').toString(),
      curriculumBasis: (json['curriculum_basis'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      subjects: rawSubjects is List
          ? rawSubjects
              .whereType<Map>()
              .map((item) => CurriculumSubject.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((subject) => subject.name.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class CurriculumRepository {
  static const String assetPath =
      'assets/data/curriculum_catalog_2027.json';

  Future<CurriculumCatalog> loadCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('ملف فهرس المناهج ليس كائن JSON صالحًا.');
    }
    final catalog = CurriculumCatalog.fromJson(decoded);
    if (catalog.subjects.isEmpty) {
      throw const FormatException('لا توجد مواد في فهرس المناهج.');
    }
    return catalog;
  }

  Future<CurriculumSubject?> getSubject(String? name) async {
    if (name == null || name.trim().isEmpty) return null;
    final catalog = await loadCatalog();
    for (final subject in catalog.subjects) {
      if (subject.name == name) return subject;
    }
    return null;
  }

  Future<CurriculumLesson?> getLesson({
    required String? subjectName,
    required String? unitName,
    required String? lessonName,
  }) async {
    final subject = await getSubject(subjectName);
    if (subject == null || unitName == null || lessonName == null) return null;
    for (final unit in subject.units) {
      if (unit.name != unitName) continue;
      for (final lesson in unit.lessons) {
        if (lesson.name == lessonName) return lesson;
      }
    }
    return null;
  }
}
