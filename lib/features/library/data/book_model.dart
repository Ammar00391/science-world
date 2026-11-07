class BookModel {
  final String id; // UUID
  final String title;
  final String grade;
  final String subject;
  final String chapter; // optional
  final String year; // e.g., "2026–2027"
  final String edition; // optional
  final String publisher;
  final String fileUrl; // HTTPS URL to PDF
  final int fileSize; // bytes
  final String fileType; // e.g., "application/pdf"
  final DateTime lastChecked;
  final bool isAvailable;
  final String rights; // e.g., "حقوق نشر © 2026"
  final String? description; // optional
  final String? coverUrl; // optional
  final int? pageCount; // optional
  final String? language; // optional

  const BookModel({
    required this.id,
    required this.title,
    required this.grade,
    required this.subject,
    this.chapter = "",
    required this.year,
    this.edition = "",
    required this.publisher,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.lastChecked,
    required this.isAvailable,
    required this.rights,
    this.description,
    this.coverUrl,
    this.pageCount,
    this.language,
  });
}
