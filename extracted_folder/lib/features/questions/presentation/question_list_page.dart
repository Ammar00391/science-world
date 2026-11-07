import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/question_service.dart';
import '../data/question_model.dart';

class QuestionListPage extends StatefulWidget {
  const QuestionListPage({super.key});

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  final QuestionService _service = QuestionService();
  List<QuestionModel> _questions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchQuestions();
      setState(() {
        _questions = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بنك الأسئلة')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : _questions.isEmpty
                    ? const Center(child: Text('لا توجد أسئلة متاحة حالياً'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final q = _questions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(q.questionText),
                              subtitle: Text('المادة: ${q.subject} | الصف: ${q.grade}'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                context.push('/question-detail/${q.id}');
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
