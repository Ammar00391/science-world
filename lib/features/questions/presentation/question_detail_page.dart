import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/support_contacts.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/gamification_service.dart';
import '../data/question_service.dart';
import '../data/question_model.dart';

class QuestionDetailPage extends StatefulWidget {
  final String questionId;
  const QuestionDetailPage({required this.questionId, super.key});

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  final QuestionService _service = QuestionService();
  QuestionModel? _question;
  bool _loading = true;
  bool _checkingAnswer = false;
  bool _revealingAnswer = false;
  bool _answeredCorrectly = false;
  String? _selectedAnswer;
  String? _revealedAnswer;
  String? _revealedSolution;
  String? _error;
  final _soundService = SoundService();
  final _gamificationService = GamificationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _checkingAnswer = false;
      _revealingAnswer = false;
      _answeredCorrectly = false;
      _selectedAnswer = null;
      _revealedAnswer = null;
      _revealedSolution = null;
    });
    try {
      final q = await _service.fetchQuestionById(widget.questionId);
      if (!mounted) return;
      setState(() {
        _question = q;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _revealAnswer() async {
    final question = _question;
    if (question == null || _revealingAnswer || _revealedAnswer != null) return;

    setState(() => _revealingAnswer = true);
    try {
      final result = await _service.revealAnswer(question: question);
      if (!mounted) return;
      setState(() {
        _revealingAnswer = false;
        _revealedAnswer = result?.answer;
        _revealedSolution = result?.solution;
      });
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('إظهار الإجابة متاح للمشتركين الفضي والذهبي.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _revealingAnswer = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إظهار الإجابة الآن. حاول مجددًا.')),
      );
    }
  }

  Future<void> _reportQuestion() async {
    final question = _question;
    if (question == null) return;
    final body = [
      'معرف السؤال: ${question.id}',
      'الصف: ${question.grade}',
      'المادة: ${question.subject}',
      'الدرس: ${question.lesson ?? 'غير محدد'}',
      'وصف المشكلة:',
    ].join('\n');

    try {
      final opened = await launchUrl(
        SupportContacts.emailUri(
          subject: 'الإبلاغ عن سؤال خاطئ',
          body: body,
        ),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'أُعدّت رسالة البلاغ. أرسلها من تطبيق البريد لإكمال الإبلاغ.'
                : 'تعذر فتح تطبيق البريد.',
          ),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق البريد للإبلاغ عن السؤال.')),
      );
    }
  }

  Future<void> _submitAnswer(String option) async {
    final question = _question;
    if (question == null || _checkingAnswer || _answeredCorrectly) return;

    setState(() => _checkingAnswer = true);
    try {
      final result = await _service.checkAnswer(
        question: question,
        selectedAnswer: option,
      );
      if (!mounted) return;

      setState(() {
        _checkingAnswer = false;
        if (result.isCorrect) {
          _answeredCorrectly = true;
          _selectedAnswer = option;
          _revealedSolution = result.solution;
        }
      });

      if (result.isCorrect) {
        final before = await _gamificationService.load();
        final after = await _gamificationService.recordCorrectAnswer();
        await _soundService.playCorrect();
        await _soundService.playXp();
        if (after.level > before.level) await _soundService.playLevelUp();
        if (after.achievements.length > before.achievements.length) {
          await _soundService.playAchievement();
        }
      } else {
        await _soundService.playWrong();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isCorrect
              ? 'إجابة صحيحة، أحسنت!'
              : 'الإجابة غير صحيحة، حاول مرة أخرى'),
          backgroundColor: result.isCorrect ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingAnswer = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر التحقق من الإجابة الآن. تحقق من الاتصال ثم أعد المحاولة.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل السؤال')),
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
                : _question == null
                    ? const Center(child: Text('السؤال غير موجود'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _question!.questionText,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text('الخيارات:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (!_question!.id.startsWith('local-'))
                              OutlinedButton.icon(
                                onPressed: _revealingAnswer ? null : _revealAnswer,
                                icon: _revealingAnswer
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.lightbulb_outline),
                                label: const Text('إظهار الإجابة للمشتركين'),
                              ),
                            if (_revealedAnswer != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'الإجابة النموذجية:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(_revealedAnswer!),
                              if ((_revealedSolution ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'شرح الحل:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(_revealedSolution!),
                              ],
                            ],
                            const SizedBox(height: 12),
                            if (_question!.options.isEmpty)
                              const Text('لا توجد خيارات')
                            else
                              Column(
                                children: _question!.options
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final idx = entry.key;
                                      final option = entry.value;
                                      final isSelected = _answeredCorrectly &&
                                          option == _selectedAnswer;
                                      return GestureDetector(
                                        onTap: _checkingAnswer || _answeredCorrectly
                                            ? null
                                            : () => _submitAnswer(option),
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.green.withValues(alpha: 0.10)
                                                : null,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.green
                                                  : Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text('${idx + 1}. $option')),
                                              if (isSelected)
                                                const Icon(Icons.check_circle, color: Colors.green),
                                              if (_checkingAnswer && !isSelected)
                                                const SizedBox.shrink(),
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _reportQuestion,
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('الإبلاغ عن سؤال خاطئ'),
                            ),
                            if (_checkingAnswer) ...[
                              const SizedBox(height: 8),
                              const Center(child: CircularProgressIndicator()),
                            ],
                            if (_answeredCorrectly) ...[
                              const SizedBox(height: 16),
                              const Text('الإجابة الصحيحة:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_selectedAnswer ?? ''),
                              if ((_revealedSolution ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text('شرح الحل:',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(_revealedSolution!),
                              ],
                            ],
                          ],
                        ),
                      ),
      ),
    );
  }
}
