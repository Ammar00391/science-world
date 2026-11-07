import 'package:flutter/material.dart';
import '../data/book_repository.dart';
import '../data/book_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});
  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final BookRepository _repo = BookRepository();
  List<BookModel> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    // No real books available yet – keep list empty
    setState(() {
      _books = [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_books.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('مكتبة الكتب')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'لم يتم إضافة كتب موثوقة لهذا الصف حتى الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://moed.gov.sy/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('زيارة وزارة التربية السورية'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة الكتب')),
      body: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text('${book.grade} – ${book.subject} – ${book.chapter}'),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailPage(book: book),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BookDetailPage extends StatelessWidget {
  final BookModel book;
  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الصف: ${book.grade}'),
            Text('المادة: ${book.subject}'),
            Text('الفصل: ${book.chapter}'),
            Text('السنة الدراسية: ${book.year}'),
            Text('الطبعة: ${book.edition}'),
            Text('الناشر: ${book.publisher}'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await BookRepository().openBook(book);
              },
              child: const Text('فتح الكتاب'),
            ),
          ],
        ),
      ),
    );
  }
}
