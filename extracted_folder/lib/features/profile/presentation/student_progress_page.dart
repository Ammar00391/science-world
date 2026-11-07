import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../test/data/local_exam_attempt_store.dart';

class StudentProgressPage extends StatefulWidget {
  const StudentProgressPage({super.key});

  @override
  State<StudentProgressPage> createState() => _StudentProgressPageState();
}

class _StudentProgressPageState extends State<StudentProgressPage> {
  final LocalExamAttemptStore _attemptStore = LocalExamAttemptStore();
  bool _loading = true;
  List<Map<String, dynamic>> _localAttempts = const [];
  int? _cloudAttempts;
  String? _cloudMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final local = await _attemptStore.load();
    int? cloudCount;
    String? cloudMessage;
    try {
      if (!SupabaseConfig.isInitialized) {
        throw Exception('Supabase غير مهيأ');
      }
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      final rows = await client
          .from('exam_attempts')
          .select('id')
          .eq('user_id', user.id);
      cloudCount = (rows as List).length;
    } catch (_) {
      cloudMessage = 'المزامنة السحابية غير مفعلة لهذه المحاولات؛ البيانات الظاهرة محفوظة على هذا الجهاز فقط.';
    }
    if (!mounted) return;
    setState(() {
      _localAttempts = local;
      _cloudAttempts = cloudCount;
      _cloudMessage = cloudMessage;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('التقدم الدراسي')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.insights_rounded, size: 34),
                          const SizedBox(height: 12),
                          Text(
                            'رحلتك نحو التفوق',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('نحتفظ بمحاولات التدريب على جهازك حتى تستطيع مقارنة تقدمك دون إنترنت.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_turned_in_outlined),
                      title: const Text('محاولات محفوظة على هذا الجهاز'),
                      trailing: Text('${_localAttempts.length}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_cloudAttempts != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_done_outlined),
                        title: const Text('محاولات مسجلة في Supabase'),
                        trailing: Text('$_cloudAttempts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_localAttempts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('آخر محاولة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((_localAttempts.first['lesson'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 7),
                            Text('النتيجة: ${((_localAttempts.first['score'] as num?) ?? 0).round()}%'),
                            Text('الإجابات الصحيحة: ${_localAttempts.first['correct_answers'] ?? 0} من ${_localAttempts.first['total_questions'] ?? 0}'),
                            Text('محاولات خاطئة: ${_localAttempts.first['wrong_attempts'] ?? 0}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_cloudMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_cloudMessage!, style: const TextStyle(color: Color(0xFF718096), fontSize: 12, height: 1.6)),
                    ),
                ],
              ),
      );
}
