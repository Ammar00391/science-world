import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_model.dart';

class BookRepository {
  final Dio _dio = Dio();

  Future<List<BookModel>> fetchBooks({required String grade, required String subject}) async {
    // Query Supabase for books matching grade & subject
    final data = await Supabase.instance.client
        .from('books')
        .select()
        .eq('grade', grade)
      .eq('subject', subject);
    return data.map((e) => BookModel(
          id: e['id'] as String,
          title: e['title'] as String,
          grade: e['grade'] as String,
          subject: e['subject'] as String,
          chapter: e['chapter'] ?? '',
          year: e['year'] ?? '',
          edition: e['edition'] ?? '',
          publisher: e['publisher'] ?? '',
          fileUrl: e['file_url'] ?? '',
          fileSize: e['file_size']?.toInt() ?? 0,
          fileType: e['file_type'] ?? '',
          lastChecked: DateTime.now(),
          isAvailable: e['is_available'] ?? true,
          rights: e['rights'] ?? '',
          description: e['description'],
          coverUrl: e['cover_url'],
          pageCount: e['page_count']?.toInt(),
          language: e['language'],
        )).toList();
  }

  Future<String> downloadBook(BookModel book) async {
    if (book.fileUrl.trim().isEmpty) {
      throw Exception('File URL is empty');
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${book.id}.pdf';
    final file = File(filePath);
    if (await file.exists()) return filePath; // already downloaded
    try {
      final response = await _dio.get(book.fileUrl,
          options: Options(responseType: ResponseType.bytes));
      await file.writeAsBytes(response.data);
      return filePath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<void> openBook(BookModel book) async {
    final path = await downloadBook(book);
    await OpenFile.open(path);
  }
}
