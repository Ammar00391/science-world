import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/library/data/book_model.dart';
import 'package:science_world/features/library/data/book_repository.dart';

void main() {
  final repo = BookRepository();

  test('downloadBook throws exception if fileUrl is empty', () async {
    final book = BookModel(
      id: 'test',
      title: 'اختبار',
      grade: 'الصف التاسع',
      subject: 'العلوم',
      chapter: '',
      year: '2026–2027',
      edition: '',
      publisher: 'وزارة التربية',
      fileUrl: '',
      fileSize: 0,
      fileType: 'application/pdf',
      lastChecked: DateTime.now(),
      isAvailable: false,
      rights: '',
    );

    expect(() async => await repo.downloadBook(book), throwsException);
  });
}
