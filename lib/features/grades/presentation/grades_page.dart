import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _GradeOption {
  final String name;
  final bool available;

  const _GradeOption(this.name, {this.available = false});
}

const _grades = [
  _GradeOption('التاسع'),
  _GradeOption('العاشر العلمي'),
  _GradeOption('الحادي عشر العلمي'),
  _GradeOption('البكالوريا العلمي', available: true),
];

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الصف')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final grade = _grades[i];
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.school,
                color: grade.available ? null : Theme.of(context).disabledColor,
              ),
              title: Text(grade.name),
              subtitle: Text(
                grade.available
                    ? 'المواد والدروس المتاحة للفرع العلمي'
                    : 'المحتوى قيد الإعداد',
              ),
              trailing: Icon(
                grade.available ? Icons.chevron_left : Icons.lock_outline,
              ),
              onTap: grade.available ? () => context.push('/subjects') : null,
            ),
          );
        },
      ),
    );
  }
}