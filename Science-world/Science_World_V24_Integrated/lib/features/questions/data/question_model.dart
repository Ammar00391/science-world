import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final String id;
  final String grade;
  final String subject;
  final String? chapter;
  final String? lesson;
  final String? schoolYear;
  final String? difficulty;
  final String type;
  final String source;
  final String reviewStatus;
  final bool isPaid;
  final String correctAnswer;
  final String solution;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String questionText;
  final List<String> options;
  final String explanation;

  const QuestionModel({
    required this.id,
    required this.grade,
    required this.subject,
    this.chapter,
    this.lesson,
    this.schoolYear,
    this.difficulty,
    required this.type,
    required this.source,
    required this.reviewStatus,
    required this.isPaid,
    required this.correctAnswer,
    required this.solution,
    required this.createdAt,
    required this.updatedAt,
    this.questionText = '',
    this.options = const [],
    this.explanation = '',
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final correctAnswer = (json['correct_answer'] ?? json['correctAnswer'] ?? '').toString();
    final solution = (json['solution'] ?? json['explanation'] ?? '').toString();
    final questionText = (json['question_text'] ?? json['questionText'] ?? '').toString();
    final optionsJson = json['options'];
    final options = optionsJson is List ? optionsJson.map((e) => e.toString()).toList() : const <String>[];

    return QuestionModel(
      id: (json['id'] ?? '').toString(),
      grade: (json['grade'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      chapter: json['chapter'] as String?,
      lesson: json['lesson'] as String?,
      schoolYear: json['school_year'] as String?,
      difficulty: json['difficulty'] as String?,
      type: (json['type'] ?? 'mcq').toString(),
      source: (json['source'] ?? 'manual').toString(),
      reviewStatus: (json['review_status'] ?? 'draft').toString(),
      isPaid: json['is_paid'] == true,
      correctAnswer: correctAnswer,
      solution: solution,
      createdAt: DateTime.tryParse((json['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      questionText: questionText,
      options: options,
      explanation: solution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'chapter': chapter,
      'lesson': lesson,
      'school_year': schoolYear,
      'difficulty': difficulty,
      'type': type,
      'source': source,
      'review_status': reviewStatus,
      'is_paid': isPaid,
      'correct_answer': correctAnswer,
      'solution': solution,
      'question_text': questionText,
      'options': options,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    grade,
    subject,
    chapter,
    lesson,
    schoolYear,
    difficulty,
    type,
    source,
    reviewStatus,
    isPaid,
    correctAnswer,
    solution,
    createdAt,
    updatedAt,
    questionText,
    options,
    explanation,
  ];
}
