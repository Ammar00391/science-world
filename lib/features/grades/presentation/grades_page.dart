import 'package:flutter/material.dart';

const _grades = ['التاسع', 'العاشر العلمي', 'الحادي عشر العلمي', 'البكالوريا العلمي'];

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
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.school),
            title: Text(_grades[i]),
            subtitle: const Text('المحتوى غير متاح بعد'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('هذا الصف قيد التطوير')),
            ),
          ),
        ),
      ),
    );
  }
}