import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/sound_service.dart';
import '../../questions/data/question_model.dart';
import '../../questions/data/question_repository.dart';
import '../data/local_exam_attempt_store.dart';

class TestPage extends StatefulWidget {
  final String? subjectName;
  final String? lessonName;
  final String? unitName;

  const TestPage({super.key, this.subjectName, this.lessonName, this.unitName});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final QuestionRepository _repository = QuestionRepository();
  final SoundService _sound = SoundService();
  final LocalExamAttemptStore _attemptStore = LocalExamAttemptStore();
  late Future<List<QuestionModel>> _questionFuture;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _clock;
  int _elapsedSeconds = 0;
  int _index = 0;
  String? _selected;
  final TextEditingController _textAnswer = TextEditingController();
  final Map<String, bool> _completed = {};
  final Map<String, String> _solutions = {};
  final Map<String, String> _lastWrongAnswers = {};
  final Map<String, String> _acceptedAnswers = {};
  final Map<String, int> _wrongAttempts = {};
  final Set<String> _skipped = {};
  bool _checking = false;
  bool _finished = false;
  bool _showingFeedback = false;
  String? _error;
  int _unsupportedQuestionCount = 0;
  List<QuestionModel> _questions = const [];

  @override
  void initState() {
    super.initState();
    _questionFuture = _loadQuestions();
  }

  Future<List<QuestionModel>> _loadQuestions() async {
    if (widget.subjectName == null || widget.lessonName == null) {
      return const [];
    }
    try {
      final allQuestions = await _repository.fetchForLesson(
        subject: widget.subjectName!,
        lesson: widget.lessonName!,
        chapter: widget.unitName,
        onlyFree: false,
        limit: 500,
      );
      // Do not expose a question through an incomplete renderer. Subjective
      // answers and interactive formats need dedicated validation/rubrics.
      const supportedTypes = {'mcq', 'single_choice', 'true_false', 'fill_blank', 'short_answer'};
      final questions = allQuestions
          .where((question) => supportedTypes.contains(question.type.toLowerCase()))
          .toList(growable: false);
      if (!mounted) return questions;
      setState(() {
        _questions = questions;
        _unsupportedQuestionCount = allQuestions.length - questions.length;
        if (questions.isNotEmpty) {
          _stopwatch.start();
          _clock = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted || _finished) return;
            setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
          });
        }
      });
      return questions;
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
      rethrow;
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _stopwatch.stop();
    _textAnswer.dispose();
    _sound.dispose();
    super.dispose();
  }

  QuestionModel? get _current =>
      _questions.isEmpty || _index >= _questions.length ? null : _questions[_index];

  String get _answerValue {
    final question = _current;
    if (question == null) return '';
    if (question.type == 'fill_blank' || question.type == 'short_answer') {
      return _textAnswer.text.trim();
    }
    return _selected ?? '';
  }

  Future<void> _submit() async {
    final question = _current;
    if (question == null || _checking || _showingFeedback) return;
    final answer = _answerValue;
    if (answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر إجابة أو اكتبها أولًا.')),
      );
      return;
    }

    setState(() => _checking = true);
    try {
      final result = await _repository.checkAnswer(
        question: question,
        selectedAnswer: answer,
      );
      if (!mounted) return;
      setState(() {
        _checking = false;
        _showingFeedback = true;
        if (result.isCorrect) {
          _completed[question.id] = true;
          _acceptedAnswers[question.id] = answer;
          if ((result.solution ?? '').trim().isNotEmpty) {
            _solutions[question.id] = result.solution!;
          }
        } else {
          _wrongAttempts.update(question.id, (count) => count + 1, ifAbsent: () => 1);
          _lastWrongAnswers[question.id] = answer;
        }
      });
      if (result.isCorrect) {
        await _sound.playCorrect();
      } else {
        await _sound.playWrong();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر التحقق من الإجابة. أعد المحاولة عند توفر الاتصال.'),
        ),
      );
    }
  }

  void _retryCurrent() {
    setState(() {
      _showingFeedback = false;
      _selected = null;
      _textAnswer.clear();
    });
  }

  void _next() {
    if (_current == null) return;
    setState(() {
      _index++;
      _selected = null;
      _textAnswer.clear();
      _showingFeedback = false;
    });
    if (_index >= _questions.length) _finish();
  }

  Future<void> _skip() async {
    final question = _current;
    if (question == null || _checking || _finished) return;
    setState(() => _checking = true);
    try {
      await _repository.recordSkippedAttempt(question: question);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _skipped.add(question.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ تخطي السؤال. لم يتم الانتقال؛ حاول مجددًا.'),
        ),
      );
      return;
    }
    _next();
  }

  Future<void> _confirmFinish() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنهاء الاختبار؟'),
        content: const Text('ستظهر نتيجة الجلسة الحالية، وتُحتسب الأسئلة التي لم تُكملها ضمن المتروك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('متابعة الاختبار'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (shouldFinish == true) _finish();
  }

  void _finish() {
    if (_finished) return;
    _clock?.cancel();
    _stopwatch.stop();
    setState(() {
      _finished = true;
      _elapsedSeconds = _stopwatch.elapsed.inSeconds;
    });
    unawaited(_persistAttempt());
  }

  Future<void> _persistAttempt() async {
    final reviews = _questions.map((question) {
      return {
        'question_id': question.id,
        'question_text': question.questionText,
        'was_correct': _completed[question.id] == true,
        'wrong_attempts': _wrongAttempts[question.id] ?? 0,
        'last_wrong_answer': _lastWrongAnswers[question.id],
        'accepted_answer': _acceptedAnswers[question.id],
        'solution_after_correct_answer': _solutions[question.id],
      };
    }).toList(growable: false);

    await _attemptStore.save({
      'completed_at': DateTime.now().toIso8601String(),
      'subject': widget.subjectName ?? '',
      'lesson': widget.lessonName ?? '',
      'unit': widget.unitName ?? '',
      'total_questions': _questions.length,
      'correct_answers': _correctCount,
      'wrong_attempts': _wrongAttemptCount,
      'unanswered': _unansweredCount,
      'score': _score,
      'elapsed_seconds': _elapsedSeconds,
      'question_reviews': reviews,
    });
  }


  void _restart() {
    _clock?.cancel();
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {
      _elapsedSeconds = 0;
      _index = 0;
      _selected = null;
      _textAnswer.clear();
      _completed.clear();
      _solutions.clear();
      _lastWrongAnswers.clear();
      _acceptedAnswers.clear();
      _wrongAttempts.clear();
      _skipped.clear();
      _checking = false;
      _finished = false;
      _showingFeedback = false;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  int get _correctCount => _completed.values.where((value) => value).length;
  int get _wrongAttemptCount => _wrongAttempts.values.fold(0, (sum, value) => sum + value);
  int get _wrongQuestionCount => _wrongAttempts.length;
  int get _unansweredCount => _questions.length - _completed.length;
  double get _score => _questions.isEmpty ? 0 : (_correctCount / _questions.length) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_finished ? 'نتيجة التدريب' : 'تدريب الدرس'),
        actions: [
          if (_questions.isNotEmpty && !_finished)
            TextButton(onPressed: _confirmFinish, child: const Text('إنهاء')),
        ],
      ),
      body: FutureBuilder<List<QuestionModel>>(
        future: _questionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || _error != null) {
            return _EmptyState(
              title: 'تعذر تحميل التدريب',
              message: 'تحقق من الاتصال أو أعد المحاولة. لا يتم فتح جداول الإجابات مباشرة.',
              onBack: () => context.pop(),
            );
          }
          if (_questions.isEmpty) {
            return _EmptyState(
              title: _unsupportedQuestionCount > 0
                  ? 'أنماط الأسئلة لهذا الدرس قيد التجهيز'
                  : 'لا توجد أسئلة معتمدة لهذا الدرس بعد',
              message: _unsupportedQuestionCount > 0
                  ? 'توجد $_unsupportedQuestionCount أسئلة معتمدة، لكن نوعها يحتاج عارضًا وتصحيحًا مخصصين. لم نعرضها قبل تجهيز ذلك.'
                  : 'المسودات غير المنشورة مخفية عن الطلاب. ستظهر الأسئلة هنا بعد مراجعة المدرس واعتماد السؤال والإجابة والحل والمصدر.',
              onBack: () => context.pop(),
            );
          }
          if (_finished) return _buildResults();
          final question = _current;
          if (question == null) return _buildResults();
          return _buildQuestion(question);
        },
      ),
    );
  }

  Widget _buildQuestion(QuestionModel question) {
    final progress = (_index + 1) / _questions.length;
    final type = question.type.toLowerCase();
    final isText = type == 'fill_blank' || type == 'short_answer';
    final isTrueFalse = type == 'true_false';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF1769E8)),
                    const SizedBox(width: 6),
                    Text(_formatTime(_elapsedSeconds), style: const TextStyle(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('${_index + 1} / ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(value: progress, minHeight: 8),
                ),
                const SizedBox(height: 15),
                Text(question.lesson ?? widget.lessonName ?? '', style: const TextStyle(color: Color(0xFF718096), fontSize: 11)),
                const SizedBox(height: 8),
                Text(question.questionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.55)),
                const SizedBox(height: 14),
                if (isText)
                  TextField(
                    controller: _textAnswer,
                    enabled: !_showingFeedback && !_checking,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'اكتب إجابتك',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  ...((isTrueFalse ? const ['صح', 'خطأ'] : question.options).map(_answerOption)),
                if (_checking) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_showingFeedback) ...[
                  const SizedBox(height: 12),
                  _FeedbackPanel(
                    isCorrect: _completed[question.id] == true,
                    message: _completed[question.id] == true
                        ? 'إجابة صحيحة، أحسنت!'
                        : 'ليست صحيحة. راجع الفكرة وحاول مرة أخرى.',
                    solution: _solutions[question.id],
                  ),
                  const SizedBox(height: 12),
                  if (_completed[question.id] == true)
                    FilledButton(onPressed: _next, child: const Text('السؤال التالي'))
                  else
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _retryCurrent, child: const Text('حاول مجددًا'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextButton(onPressed: _checking ? null : _skip, child: const Text('تخطي السؤال'))),
                      ],
                    ),
                ] else ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _checking ? null : _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تحقق من الإجابة'),
                  ),
                  TextButton(onPressed: _checking ? null : _skip, child: const Text('تخطي هذا السؤال')),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniStat(label: 'صحيحة', value: '$_correctCount', color: const Color(0xFF15966A)),
            const SizedBox(width: 8),
            _MiniStat(label: 'محاولات خاطئة', value: '$_wrongAttemptCount', color: const Color(0xFFD9485F)),
            const SizedBox(width: 8),
            _MiniStat(label: 'متروكة', value: '${_skipped.length}', color: const Color(0xFF718096)),
          ],
        ),
      ],
    );
  }

  Widget _answerOption(String option) {
    final selected = _selected == option;
    final disabled = _showingFeedback || _checking;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: disabled ? null : () => setState(() => _selected = option),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF1769E8) : const Color(0xFFE5EAF2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? const Color(0xFF1769E8) : const Color(0xFF718096),
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(option, style: const TextStyle(height: 1.4))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final percent = _score.round();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFF1769E8), size: 42),
              const SizedBox(height: 8),
              Text('$percent%', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF102E54))),
              const Text('نسبة الإجابات الصحيحة', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('الوقت المستغرق: ${_formatTime(_elapsedSeconds)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _ResultMetric(title: 'صحيحة', value: '$_correctCount', color: const Color(0xFF15966A))),
            const SizedBox(width: 8),
            Expanded(child: _ResultMetric(title: 'أسئلة بها خطأ', value: '$_wrongQuestionCount', color: const Color(0xFFD9485F))),
            const SizedBox(width: 8),
            Expanded(child: _ResultMetric(title: 'متروكة', value: '$_unansweredCount', color: const Color(0xFF718096))),
          ],
        ),
        const SizedBox(height: 8),
        Text('إجمالي المحاولات الخاطئة: $_wrongAttemptCount', style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
        const SizedBox(height: 16),
        const Text('مراجعة أدائك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ..._questions.map((question) {
          final wasCorrect = _completed[question.id] == true;
          final attempts = _wrongAttempts[question.id] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                wasCorrect ? Icons.check_circle : Icons.info_outline,
                color: wasCorrect ? const Color(0xFF15966A) : const Color(0xFF718096),
              ),
              title: Text(question.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(wasCorrect
                  ? 'أُجيبت إجابة صحيحة${attempts > 0 ? ' بعد $attempts محاولة خاطئة' : ''}'
                  : 'لم تُستكمل الإجابة؛ آخر إجابة: ${_lastWrongAnswers[question.id] ?? 'لم تُجب'}'),
            ),
          );
        }),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('إعادة الاختبار من البداية'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => context.go('/subjects'), child: const Text('اختيار مادة أخرى')),
      ],
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String? solution;
  const _FeedbackPanel({required this.isCorrect, required this.message, this.solution});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF15966A) : const Color(0xFFD9485F);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: color), const SizedBox(width: 8), Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w800))) ]),
          if ((solution ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(solution!, style: const TextStyle(height: 1.6)),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5EAF2))),
          child: Column(children: [Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)), Text(label, style: const TextStyle(color: Color(0xFF718096), fontSize: 10))]),
        ),
      );
}

class _ResultMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _ResultMetric({required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EAF2))),
        child: Column(children: [Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 21)), Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF718096)))]),
      );
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;
  const _EmptyState({required this.title, required this.message, required this.onBack});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fact_check_outlined, size: 48, color: Color(0xFF1769E8)),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.6, color: Color(0xFF718096))),
              const SizedBox(height: 15),
              OutlinedButton(onPressed: onBack, child: const Text('العودة')),
            ],
          ),
        ),
      );
}
