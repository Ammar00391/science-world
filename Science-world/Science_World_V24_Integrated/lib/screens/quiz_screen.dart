import 'package:flutter/material.dart';

import '../features/questions/data/question_model.dart';
import '../features/questions/data/question_repository.dart';

/// شاشة تدريب الدرس.
///
/// ملاحظة توافق: لا يحتوي مخطط questions الحالي على عمود lesson_id؛ إذ يربط
/// الأسئلة بالدرس من خلال subject وchapter وlesson. لذلك نحتفظ بـ lessonId
/// كسياق للتنقل والتحقق، بينما يتم جلب الأسئلة عبر واجهة RPC الآمنة الموجودة
/// في QuestionRepository، وليس عبر SELECT مباشر قد يكشف الإجابات الصحيحة.
class QuizScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String subjectName;
  final String? unitName;

  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.subjectName,
    this.unitName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionRepository _repository = QuestionRepository();
  final TextEditingController _textAnswerController = TextEditingController();

  late final Future<List<QuestionModel>> _questionsFuture;
  List<QuestionModel> _questions = const [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isChecking = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  String? _solution;

  QuestionModel? get _currentQuestion =>
      _questions.isEmpty || _currentIndex >= _questions.length
          ? null
          : _questions[_currentIndex];

  bool get _isTextQuestion {
    final type = _currentQuestion?.type.toLowerCase();
    return type == 'fill_blank' || type == 'short_answer';
  }

  List<String> get _currentOptions {
    final question = _currentQuestion;
    if (question == null) return const [];
    if (question.type.toLowerCase() == 'true_false') {
      return const ['صح', 'خطأ'];
    }
    return question.options;
  }

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();
  }

  Future<List<QuestionModel>> _fetchQuestions() async {
    if (widget.lessonId.trim().isEmpty) {
      throw const FormatException('معرّف الدرس غير صالح.');
    }
    if (widget.subjectName.trim().isEmpty || widget.lessonTitle.trim().isEmpty) {
      throw const FormatException('بيانات المادة أو الدرس غير مكتملة.');
    }

    final fetched = await _repository.fetchForLesson(
      subject: widget.subjectName,
      lesson: widget.lessonTitle,
      chapter: widget.unitName,
      onlyFree: false,
      limit: 500,
    );

    const supportedTypes = {
      'mcq',
      'single_choice',
      'true_false',
      'fill_blank',
      'short_answer',
    };
    _questions = fetched
        .where((question) => supportedTypes.contains(question.type.toLowerCase()))
        .where((question) =>
            question.type.toLowerCase() == 'true_false' ||
            question.type.toLowerCase() == 'fill_blank' ||
            question.type.toLowerCase() == 'short_answer' ||
            question.options.isNotEmpty)
        .toList(growable: false);

    return _questions;
  }

  @override
  void dispose() {
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final question = _currentQuestion;
    if (question == null || _isChecking || _isAnswered) return;

    final answer = _isTextQuestion
        ? _textAnswerController.text.trim()
        : (_selectedAnswer ?? '').trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر إجابة أو اكتبها أولًا.')),
      );
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _repository.checkAnswer(
        question: question,
        selectedAnswer: answer,
      );
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _isAnswered = true;
        _isCorrect = result.isCorrect;
        _solution = result.solution;
        if (result.isCorrect) _score++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر التحقق من الإجابة. تحقق من الاتصال ثم أعد المحاولة.'),
        ),
      );
    }
  }

  void _retryQuestion() {
    setState(() {
      _selectedAnswer = null;
      _textAnswerController.clear();
      _isAnswered = false;
      _isCorrect = null;
      _solution = null;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _textAnswerController.clear();
        _isAnswered = false;
        _isCorrect = null;
        _solution = null;
      });
      return;
    }
    _showResultDialog();
  }

  Future<void> _showResultDialog() async {
    final total = _questions.length;
    final percentage = total == 0 ? 0 : (_score / total * 100).round();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نتيجة التدريب'),
        content: Text(
          'أكملت تدريب درس ${widget.lessonTitle}.\n\n'
          'نتيجتك: $_score من $total ($percentage٪)',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار: ${widget.lessonTitle}'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<QuestionModel>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.cloud_off_outlined,
              message: 'تعذر تحميل أسئلة هذا الدرس. تحقق من الاتصال وحاول مجددًا.',
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildMessage(
              icon: Icons.quiz_outlined,
              message: 'لا توجد أسئلة معتمدة مضافة لهذا الدرس حتى الآن.',
            );
          }

          return _buildQuestionContent();
        },
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('العودة إلى الدرس'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = _currentQuestion;
    if (question == null) {
      return const Center(child: Text('انتهى التدريب.'));
    }

    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.grey.shade200,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 18),
          Text(
            'السؤال ${_currentIndex + 1} من ${_questions.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (_isTextQuestion)
            TextField(
              controller: _textAnswerController,
              enabled: !_isAnswered && !_isChecking,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'اكتب إجابتك',
                border: OutlineInputBorder(),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _currentOptions.map(_buildAnswerOption).toList(),
              ),
            ),
          if (_isChecking) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_isAnswered) ...[
            const SizedBox(height: 14),
            _buildFeedback(),
            const SizedBox(height: 12),
            if (_isCorrect == true)
              FilledButton(
                onPressed: _nextQuestion,
                child: Text(
                  _currentIndex < _questions.length - 1
                      ? 'السؤال التالي'
                      : 'عرض النتيجة',
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retryQuestion,
                      child: const Text('حاول مجددًا'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: _nextQuestion,
                      child: const Text('تخطي السؤال'),
                    ),
                  ),
                ],
              ),
          ] else ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _isChecking ? null : _submitAnswer,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تحقق من الإجابة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String option) {
    final selected = _selectedAnswer == option;
    final disabled = _isAnswered || _isChecking;
    Color background = Colors.white;
    Color border = Colors.grey.shade300;

    if (selected && _isAnswered) {
      background = _isCorrect == true ? Colors.green.shade50 : Colors.red.shade50;
      border = _isCorrect == true ? Colors.green : Colors.red;
    } else if (selected) {
      background = Colors.blue.shade50;
      border = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        value: option,
        groupValue: _selectedAnswer,
        onChanged: disabled ? null : (value) => setState(() => _selectedAnswer = value),
        title: Text(option, style: const TextStyle(color: Colors.black87)),
        activeColor: Colors.blueAccent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _isCorrect == true;
    final color = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect ? 'إجابة صحيحة، أحسنت!' : 'الإجابة غير صحيحة، حاول مرة أخرى.',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (isCorrect && (_solution ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_solution!, style: const TextStyle(height: 1.5)),
          ],
        ],
      ),
    );
  }
}
