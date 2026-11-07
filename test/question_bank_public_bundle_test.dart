import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('student bundle contains only reviewed questions', () async {
    final raw = await rootBundle.loadString('assets/data/question_bank_ar.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final questions = decoded['questions'] as List<dynamic>;
    for (final rawQuestion in questions) {
      final question = Map<String, dynamic>.from(rawQuestion as Map);
      expect(
        {'approved', 'published'}.contains(question['review_status']),
        isTrue,
        reason: 'Draft question ${question['id']} must never be packaged.',
      );
    }
    // This initial release intentionally has no approved offline questions.
    expect(questions, isEmpty);
    expect(decoded['status'], 'no_approved_questions_yet');
  });
}
