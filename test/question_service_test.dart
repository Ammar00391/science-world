import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/questions/data/question_model.dart';
import 'package:science_world/features/questions/data/question_service.dart';

void main() {
  test('QuestionService should be instantiable', () {
    final service = QuestionService();
    expect(service, isNotNull);
  });

  test('sanitized remote question payload does not contain the answer or solution', () {
    final question = QuestionModel.fromJson({
      'id': '11111111-1111-4111-8111-111111111111',
      'grade': 'التاسع',
      'subject': 'الرياضيات',
      'type': 'mcq',
      'source': 'manual',
      'review_status': 'published',
      'is_paid': false,
      'question_text': 'ما ناتج 2 + 2؟',
      'options': ['3', '4', '5'],
      'created_at': '2026-11-04T00:00:00Z',
      'updated_at': '2026-11-04T00:00:00Z',
    });

    expect(question.questionText, 'ما ناتج 2 + 2؟');
    expect(question.options, ['3', '4', '5']);
    expect(question.correctAnswer, isEmpty);
    expect(question.solution, isEmpty);
    expect(question.explanation, isEmpty);
  });
}
