import 'package:flutter/material.dart';

import '../services/curriculum_service.dart';
import 'lesson_detail_screen.dart';

class UnitsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const UnitsScreen({
    super.key,
    required this.subjectId,
    String? subjectName,
    String? subjectTitle,
  }) : subjectName = subjectName ?? subjectTitle ?? 'المادة';

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final CurriculumService _curriculumService = CurriculumService();
  late Future<List<Map<String, dynamic>>> _unitsFuture;
  final Map<String, Future<List<Map<String, dynamic>>>> _lessonFutures = {};

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  void _loadUnits() {
    _lessonFutures.clear();
    _unitsFuture = _curriculumService.getUnitsForSubject(widget.subjectId);
  }

  Future<void> _refresh() async {
    setState(_loadUnits);
    try {
      await _unitsFuture;
    } catch (_) {
      // FutureBuilder below renders the detailed error state.
    }
  }

  Future<List<Map<String, dynamic>>> _lessonsFor(String unitId) {
    return _lessonFutures.putIfAbsent(
      unitId,
      () => _curriculumService.getLessonsForUnit(unitId),
    );
  }

  String _label(Map<String, dynamic> row, {required String fallback}) {
    final value = (row['title'] ?? row['name'] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'تعذر تحميل الوحدات من قاعدة البيانات.\n${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final units = snapshot.data ?? const <Map<String, dynamic>>[];
          if (units.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد وحدات مضافة لهذه المادة بعد.')),
                  SizedBox(height: 220),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final unitId = (unit['id'] ?? '').toString();
                final unitName = _label(
                  unit,
                  fallback: 'الوحدة ${index + 1}',
                );

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: PageStorageKey<String>('unit-$unitId'),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      unitName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('اضغط لعرض الدروس'),
                    children: [
                      if (unitId.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا يحتوي سجل الوحدة على معرّف صالح.'),
                        )
                      else
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _lessonsFor(unitId),
                          builder: (context, lessonSnapshot) {
                            if (lessonSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(18),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (lessonSnapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'تعذر تحميل دروس هذه الوحدة. '
                                  'تحقق من جدول lessons وصلاحيات RLS.\n'
                                  '${lessonSnapshot.error}',
                                ),
                              );
                            }

                            final lessons = lessonSnapshot.data ??
                                const <Map<String, dynamic>>[];
                            if (lessons.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('لا توجد دروس مضافة في هذه الوحدة بعد.'),
                              );
                            }

                            return Column(
                              children: [
                                for (var lessonIndex = 0;
                                    lessonIndex < lessons.length;
                                    lessonIndex++)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.menu_book_outlined,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      _label(
                                        lessons[lessonIndex],
                                        fallback: 'الدرس ${lessonIndex + 1}',
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 15,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => LessonDetailScreen(
                                            lesson: lessons[lessonIndex],
                                            subjectName: widget.subjectName,
                                            unitName: unitName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
