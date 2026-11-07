import 'package:flutter/material.dart';

import '../../test/data/local_exam_attempt_store.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final LocalExamAttemptStore _store = LocalExamAttemptStore();
  late Future<List<Map<String, dynamic>>> _attempts;

  @override
  void initState() {
    super.initState();
    _attempts = _store.load();
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'تاريخ غير متاح';
    final local = date.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دفتر مراجعة الاختبارات')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attempts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snapshot.data ?? const <Map<String, dynamic>>[];
          if (attempts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد محاولات محفوظة على هذا الجهاز بعد. بعد إنهاء أول تدريب ستجد هنا الأسئلة التي أجبت عنها والمحاولات الخاطئة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.7),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'محاولاتك الأخيرة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...attempts.map((attempt) {
                final subject = (attempt['subject'] ?? '').toString();
                final lesson = (attempt['lesson'] ?? '').toString();
                final score = (attempt['score'] as num?)?.toDouble() ?? 0;
                final correct = attempt['correct_answers'] ?? 0;
                final total = attempt['total_questions'] ?? 0;
                final rawReviews = attempt['question_reviews'];
                final reviews = rawReviews is List
                    ? rawReviews.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
                    : <Map<String, dynamic>>[];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF2FF),
                      child: Text('${score.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1769E8))),
                    ),
                    title: Text(lesson, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('$subject • $correct من $total • ${_dateLabel(attempt['completed_at'])}'),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    children: reviews.map((review) {
                      final wasCorrect = review['was_correct'] == true;
                      final wrongAnswer = (review['last_wrong_answer'] ?? '').toString();
                      final acceptedAnswer = (review['accepted_answer'] ?? '').toString();
                      final solution = (review['solution_after_correct_answer'] ?? '').toString();
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: wasCorrect ? const Color(0xFFF0FAF5) : const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(wasCorrect ? Icons.check_circle : Icons.error_outline,
                                    color: wasCorrect ? const Color(0xFF15966A) : const Color(0xFFD9485F), size: 19),
                                const SizedBox(width: 8),
                                Expanded(child: Text((review['question_text'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (wasCorrect && acceptedAnswer.isNotEmpty)
                              Text('إجابتك الصحيحة: $acceptedAnswer')
                            else if (wrongAnswer.isNotEmpty)
                              Text('آخر إجابة غير صحيحة: $wrongAnswer'),
                            if (solution.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('التفسير: $solution', style: const TextStyle(height: 1.5)),
                            ] else if (!wasCorrect)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'لم يُرجع الخادم الحل لهذا السؤال؛ لا نعرض مفتاح الإجابة من التطبيق.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
              const SizedBox(height: 10),
              const Text(
                'تُحفظ هذه المراجعة محليًا على الجهاز، ولا تعني أنها تزامنت مع حسابك أو مع جهاز آخر.',
                style: TextStyle(color: Color(0xFF718096), fontSize: 11, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }
}
