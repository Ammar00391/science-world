import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:science_world/features/test/data/local_exam_attempt_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and reads a local attempt without requiring Supabase', () async {
    final store = LocalExamAttemptStore();
    await store.save({
      'subject': 'الرياضيات – الجزء الأول',
      'lesson': 'النهايات',
      'score': 75,
      'total_questions': 4,
      'correct_answers': 3,
    });

    final records = await store.load();
    expect(records, hasLength(1));
    expect(records.first['subject'], 'الرياضيات – الجزء الأول');
    expect(records.first['score'], 75);
  });

  test('keeps only the most recent 60 attempts', () async {
    final store = LocalExamAttemptStore();
    for (var index = 0; index < 65; index++) {
      await store.save({'attempt_number': index});
    }

    final records = await store.load();
    expect(records, hasLength(60));
    expect(records.first['attempt_number'], 64);
    expect(records.last['attempt_number'], 5);
  });
}
