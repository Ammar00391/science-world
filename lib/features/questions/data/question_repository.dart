import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import 'question_model.dart';

class QuestionAnswerResult {
  final bool isCorrect;
  final String? solution;

  const QuestionAnswerResult({required this.isCorrect, this.solution});
}

class QuestionRepository {
  final SupabaseClient? _client;

  QuestionRepository({SupabaseClient? client})
      : _client = client ??
            (SupabaseConfig.isInitialized ? Supabase.instance.client : null);

  /// Fetches only the safe public fields exposed by the get_questions RPC.
  /// The correct answer and solution are intentionally not returned here.
  Future<List<QuestionModel>> fetchAll({
    String? grade,
    String? subject,
    bool onlyFree = true,
    String? type,
    String? difficulty,
    int limit = 100,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client.rpc(
          'get_questions',
          params: {
            'p_grade': grade,
            'p_subject': subject,
            'p_type': type,
            'p_difficulty': difficulty,
          },
        );

        if (response is! List) {
          throw const FormatException('استجابة get_questions غير صالحة.');
        }

        final remote = response
            .map((item) => QuestionModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .where((question) =>
                question.reviewStatus == 'approved' ||
                question.reviewStatus == 'published')
            .where((question) => !onlyFree || !question.isPaid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (remote.isNotEmpty) {
          return remote.take(limit < 0 ? 0 : limit).toList();
        }
      } catch (_) {
        // The bundled question bank remains available for offline study.
        // It contains local practice items only; server questions are never
        // fetched directly from the questions table as a fallback.
      }
    }

    return _fetchLocal(
      grade: grade,
      subject: subject,
      type: type,
      difficulty: difficulty,
      limit: limit,
    );
  }

  Future<List<QuestionModel>> _fetchLocal({
    String? grade,
    String? subject,
    String? type,
    String? difficulty,
    required int limit,
  }) async {
    final raw = await rootBundle.loadString('assets/data/question_bank_ar.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['questions'] as List<dynamic>)
        .map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e)))
        .where((q) => grade == null || _sameGrade(q.grade, grade))
        .where((q) => subject == null || q.subject == subject)
        .where((q) => q.reviewStatus == 'approved' || q.reviewStatus == 'published')
        // Offline fallback is free-only: a paid question must never become
        // visible merely because a connection/subscription check failed.
        .where((q) => !q.isPaid)
        .where((q) => type == null || q.type == type)
        .where((q) => difficulty == null || q.difficulty == difficulty)
        .take(limit < 0 ? 0 : limit)
        .toList();
    return list;
  }

  /// Returns only reviewed questions belonging to one exact lesson.
  /// The lesson name is matched independently from numbering/prefix labels,
  /// so catalog labels such as 'قراءة تمهيدية:' can match older seed labels
  /// such as 'الدرس الأول:' without matching a different literary text.
  Future<List<QuestionModel>> fetchForLesson({
    required String subject,
    required String lesson,
    String? chapter,
    String grade = 'البكالوريا العلمي',
    bool onlyFree = false,
    int limit = 500,
  }) async {
    final all = await fetchAll(
      grade: grade,
      subject: subject,
      onlyFree: onlyFree,
      limit: limit,
    );
    final target = _normalizeLesson(lesson);
    if (target.isEmpty) return const [];
    return all.where((question) {
      if (chapter != null && chapter.trim().isNotEmpty && question.chapter != chapter) {
        return false;
      }
      final stored = _normalizeLesson(question.lesson ?? '');
      return stored == target ||
          (stored.length >= 12 && target.contains(stored)) ||
          (target.length >= 12 && stored.contains(target));
    }).toList(growable: false);
  }

  String _normalizeLesson(String value) {
    var result = value.toLowerCase().trim();
    const removable = [
      'قراءة تمهيدية',
      'الدرس الأول',
      'الدرس الاول',
      'الدرس الثاني',
      'الدرس الثالث',
      'الدرس الرابع',
      'الدرس الخامس',
      'الدرس السادس',
      'الدرس السابع',
      'الدرس الثامن',
      'الدرس التاسع',
      'الدرس العاشر',
    ];
    for (final prefix in removable) {
      result = result.replaceFirst(prefix, '');
    }
    result = result.replaceAll(RegExp(r'[\s:،؛,.ـ\-–—_]+'), '');
    return result;
  }

  bool _sameGrade(String stored, String requested) {
    final a = stored.replaceAll(' ', '').toLowerCase();
    final b = requested.replaceAll(' ', '').toLowerCase();
    if (a == b) return true;
    const aliases = {
      'التاسع': ['9', 'grade9', 'الصفالتاسع'],
      'العاشر': ['10', 'grade10', 'الصفالعاشر'],
      'الحاديعشرالعلمي': ['11', 'grade11', 'الحاديعشر', 'الصفالحاديعشر'],
      'البكالورياالعلمي': ['12', 'grade12', 'البكالوريا', 'الثالثالثانوي'],
    };
    for (final entry in aliases.entries) {
      final matches = entry.value.contains(a) ||
          entry.value.contains(b) ||
          a == entry.key ||
          b == entry.key;
      if (matches &&
          (a == entry.key || entry.value.contains(a)) &&
          (b == entry.key || entry.value.contains(b))) {
        return true;
      }
    }
    return false;
  }

  /// Fetches a question through the same sanitized RPC; it never selects the
  /// questions table directly. Local practice questions are loaded from the
  /// bundled offline bank when no remote row is available.
  Future<QuestionModel> fetchById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client.rpc(
          'get_question_by_id',
          params: {'p_question_id': id},
        );
        if (response is! List) {
          throw const FormatException('استجابة get_questions غير صالحة.');
        }
        for (final item in response) {
          final question = QuestionModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          if (question.id == id &&
              (question.reviewStatus == 'approved' ||
                  question.reviewStatus == 'published')) {
            return question;
          }
        }
      } catch (_) {
        // Continue to the bundled offline bank only.
      }
    }

    final all = await _fetchLocal(
      grade: null,
      subject: null,
      type: null,
      difficulty: null,
      limit: 10000,
    );
    for (final question in all) {
      if (question.id == id) return question;
    }

    return QuestionModel(
      id: id,
      grade: '',
      subject: '',
      type: 'mcq',
      source: 'local',
      reviewStatus: 'draft',
      isPaid: false,
      correctAnswer: '',
      solution: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questionText: 'السؤال غير متاح حاليا',
      options: const [],
      explanation: 'لم يتم العثور على السؤال في البنك المحلي أو الخادم.',
    );
  }

  /// Checks an answer without downloading the correct answer to the client.
  /// For bundled local practice questions, evaluation remains fully offline.
  Future<QuestionAnswerResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async {
    final client = _client;
    final isBundledQuestion = question.id.startsWith('local-');

    if (client == null || isBundledQuestion) {
      if (question.correctAnswer.trim().isEmpty) {
        throw StateError('الإجابة غير متاحة للتحقق دون اتصال.');
      }
      final isCorrect = selectedAnswer.trim().toLowerCase() ==
          question.correctAnswer.trim().toLowerCase();
      return QuestionAnswerResult(
        isCorrect: isCorrect,
        solution: isCorrect
            ? (question.solution.trim().isNotEmpty
                ? question.solution
                : question.explanation)
            : null,
      );
    }

    final response = await client.rpc(
      'check_question_answer',
      params: {
        'p_question_id': question.id,
        'p_answer': selectedAnswer,
      },
    );

    if (response is List && response.isNotEmpty) {
      final row = Map<String, dynamic>.from(response.first as Map);
      final isCorrect = row['is_correct'] == true;
      final solution = row['solution']?.toString();
      return QuestionAnswerResult(
        isCorrect: isCorrect,
        solution: isCorrect && solution != null && solution.isNotEmpty
            ? solution
            : null,
      );
    }

    throw const FormatException('تعذر قراءة نتيجة التحقق من الإجابة.');
  }

  /// Intended for trusted administration workflows only. Regular student
  /// clients do not receive INSERT/UPDATE privileges on the questions table.
  Future<void> upsert(QuestionModel question) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase غير مهيأ؛ لا يمكن حفظ السؤال في الخادم.');
    }
    await client.from('questions').upsert(question.toJson());
  }
}
