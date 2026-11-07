import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/curriculum/data/curriculum_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curriculum catalog contains the requested nine subjects in order', () async {
    final catalog = await CurriculumRepository().loadCatalog();
    expect(catalog.subjects, hasLength(9));
    expect(catalog.subjects.first.name, 'اللغة العربية وآدابها');
    expect(catalog.subjects[1].name, 'علم الأحياء والأرض');
    expect(catalog.subjects[2].name, 'التربية الإسلامية');
    expect(catalog.subjects[3].name, 'الرياضيات – الجزء الأول');
    expect(catalog.subjects[4].name, 'الرياضيات – الجزء الثاني');
    expect(catalog.subjects[5].name, 'الكيمياء');
    expect(catalog.subjects[6].name, 'الفيزياء');
    expect(catalog.subjects[7].name, 'اللغة الإنجليزية – كتاب الطالب');
    expect(catalog.subjects[8].name, 'اللغة الفرنسية');
  });

  test('each curriculum subject has at least one unit and lesson', () async {
    final catalog = await CurriculumRepository().loadCatalog();
    for (final subject in catalog.subjects) {
      expect(subject.units, isNotEmpty, reason: subject.name);
      expect(subject.lessonCount, greaterThan(0), reason: subject.name);
      for (final unit in subject.units) {
        expect(unit.lessons, isNotEmpty, reason: '${subject.name} / ${unit.name}');
      }
    }
  });

  test('every lesson exposes the four learning stages', () async {
    final catalog = await CurriculumRepository().loadCatalog();
    const requiredStages = {'summary', 'worked_example', 'common_mistakes', 'practice'};
    for (final subject in catalog.subjects) {
      for (final unit in subject.units) {
        for (final lesson in unit.lessons) {
          expect(
            lesson.learningComponents.keys.toSet().containsAll(requiredStages),
            isTrue,
            reason: '${subject.name} / ${unit.name} / ${lesson.name}',
          );
        }
      }
    }
  });
}
