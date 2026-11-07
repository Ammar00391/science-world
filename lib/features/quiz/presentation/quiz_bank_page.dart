import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../questions/data/question_model.dart';
import '../../questions/data/question_repository.dart';

class QuizBankPage extends StatefulWidget {
  const QuizBankPage({super.key});

  @override
  State<QuizBankPage> createState() => _QuizBankPageState();
}

class _QuizBankPageState extends State<QuizBankPage> {
  final QuestionRepository _repository = QuestionRepository();
  String _grade = 'الكل';
  String _subject = 'الكل';
  late Future<List<QuestionModel>> _questions;

  static const _grades = ['الكل', 'التاسع', 'العاشر', 'الحادي عشر العلمي', 'البكالوريا العلمي'];
  static const _subjects = ['الكل', 'الرياضيات', 'الفيزياء والكيمياء', 'الفيزياء', 'الكيمياء', 'علم الأحياء والأرض', 'علم الأحياء'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _questions = _repository.fetchAll(
      grade: _grade == 'الكل' ? null : _grade,
      subject: _subject == 'الكل' ? null : _subject,
      onlyFree: false,
      limit: 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بنك الأسئلة التدريبية')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(children: [
              const Text('أسئلة تدريبية مع إجابات وتفسيرات. تُراجع مطابقتها للطبعة الرسمية قبل اعتمادها.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _grade,
                  decoration: const InputDecoration(labelText: 'الصف', border: OutlineInputBorder()),
                  items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) => setState(() { _grade = value ?? 'الكل'; _load(); }),
                )),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _subject,
                  decoration: const InputDecoration(labelText: 'المادة', border: OutlineInputBorder()),
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) => setState(() { _subject = value ?? 'الكل'; _load(); }),
                )),
              ]),
            ]),
          ),
          Expanded(child: FutureBuilder<List<QuestionModel>>(
            future: _questions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 8),
                    const Text('تعذر تحميل الأسئلة. تحقق من ملف بنك الأسئلة ثم أعد المحاولة.'),
                    TextButton(onPressed: () => setState(_load), child: const Text('إعادة المحاولة')),
                  ]),
                ));
              }
              final questions = snapshot.data ?? const <QuestionModel>[];
              if (questions.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد أسئلة منشورة ومعتمدة لهذا الاختيار حاليًا. ستظهر الأسئلة بعد مراجعة المدرس، ولن نعرض المسودات غير المدققة.', textAlign: TextAlign.center)));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return Card(child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(q.questionText, maxLines: 3, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${q.grade} • ${q.subject}\n${q.options.length} خيارات • ${q.isPaid ? 'للمشتركين' : 'مجاني'}', maxLines: 2),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push('/question-detail/${Uri.encodeComponent(q.id)}'),
                  ));
                },
              );
            },
          )),
        ],
      ),
    );
  }
}
