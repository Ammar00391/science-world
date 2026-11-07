import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../curriculum/data/curriculum_repository.dart';

class LessonsPage extends StatefulWidget {
  final String? subjectName;
  const LessonsPage({super.key, this.subjectName});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final CurriculumRepository _repository = CurriculumRepository();
  late Future<CurriculumSubject?> _subject;

  @override
  void initState() {
    super.initState();
    _subject = _repository.getSubject(widget.subjectName);
  }

  String _lessonRoute(String unit, String lesson) {
    final query = Uri(queryParameters: {
      'subject': widget.subjectName ?? '',
      'unit': unit,
      'lesson': lesson,
    }).query;
    return '/lesson-detail?$query';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName ?? 'الدروس')),
      body: FutureBuilder<CurriculumSubject?>(
        future: _subject,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subject = snapshot.data;
          if (snapshot.hasError || subject == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('لم أجد هذه المادة في فهرس الصف.'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => context.go('/subjects'),
                      child: const Text('العودة إلى المواد'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: Color(0xFF1769E8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${subject.units.length} وحدات • ${subject.lessonCount} درسًا',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...subject.units.asMap().entries.map((entry) {
                final unitIndex = entry.key;
                final unit = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: unitIndex == 0,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    title: Text(
                      unit.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${unit.lessons.length} دروس'),
                    children: unit.lessons.asMap().entries.map((lessonEntry) {
                      final lessonIndex = lessonEntry.key;
                      final lesson = lessonEntry.value;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFEAF2FF),
                          child: Text(
                            '${lessonIndex + 1}',
                            style: const TextStyle(
                              color: Color(0xFF1769E8),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(lesson.name),
                        subtitle: lesson.subtopics.isEmpty
                            ? null
                            : Text('${lesson.subtopics.length} محاور فرعية'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => context.push(
                          _lessonRoute(unit.name, lesson.name),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
