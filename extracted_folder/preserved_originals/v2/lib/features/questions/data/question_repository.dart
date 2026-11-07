import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import 'question_model.dart';

class QuestionRepository {
  final SupabaseClient? _client;

  QuestionRepository({SupabaseClient? client})
      : _client = client ?? (SupabaseConfig.isConfigured ? Supabase.instance.client : null);

  Future<List<QuestionModel>> fetchAll({
    String? grade,
    String? subject,
    bool onlyFree = true,
    String? type,
    String? difficulty,
    int limit = 100,
  }) async {
    final client = _client;
    if (client == null) return const <QuestionModel>[];

    var query = client.from('questions').select();
    if (grade != null) query = query.eq('grade', grade);
    if (subject != null) query = query.eq('subject', subject);
    if (type != null) query = query.eq('type', type);
    if (difficulty != null) query = query.eq('difficulty', difficulty);
    if (onlyFree) query = query.eq('is_paid', false);

    final response = await query.limit(limit).order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data.map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<QuestionModel> fetchById(String id) async {
    final client = _client;
    if (client == null) {
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
        explanation: 'البيانات غير متاحة لأن Supabase غير مهيأ في هذا المشغل.',
      );
    }

    final response = await client.from('questions').select().eq('id', id).single();
    return QuestionModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> upsert(QuestionModel question) async {
    final client = _client;
    if (client == null) return;
    final data = question.toJson();
    await client.from('questions').upsert([data]).select();
  }
}
