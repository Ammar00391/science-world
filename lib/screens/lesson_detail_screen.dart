import 'package:flutter/material.dart';

import 'quiz_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final String? subjectName;
  final String? unitName;

  const LessonDetailScreen({
    Key? key,
    required this.lesson,
    this.subjectName,
    this.unitName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson['title'] ?? 'تفاصيل الدرس'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson['title'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'شرح الدرس:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lesson['description'] ??
                  'لا يوجد وصف تفصيلي متاح لهذا الدرس حالياً.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final lessonId = (lesson['id'] ?? '').toString();
                  final lessonTitle = (lesson['title'] ?? '').toString();
                  final resolvedSubject =
                      subjectName ?? (lesson['subject_name'] ?? '').toString();
                  final resolvedUnit =
                      unitName ?? (lesson['unit_name'] ?? '').toString();

                  if (lessonId.isEmpty ||
                      lessonTitle.isEmpty ||
                      resolvedSubject.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('بيانات الدرس أو المادة غير مكتملة لبدء التدريب.'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        lessonId: lessonId,
                        lessonTitle: lessonTitle,
                        subjectName: resolvedSubject,
                        unitName: resolvedUnit.isEmpty ? null : resolvedUnit,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text(
                  'بدء التدريب والاختبار',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
