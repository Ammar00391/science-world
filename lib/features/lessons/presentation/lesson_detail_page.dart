import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../curriculum/data/curriculum_repository.dart';
import '../../questions/data/question_model.dart';
import '../../questions/data/question_repository.dart';

class LessonDetailPage extends StatefulWidget {
  final String? subjectName;
  final String? unitName;
  final String? lessonName;

  const LessonDetailPage({
    super.key,
    this.subjectName,
    this.unitName,
    this.lessonName,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  final CurriculumRepository _curriculum = CurriculumRepository();
  final QuestionRepository _questions = QuestionRepository();
  late Future<CurriculumLesson?> _lesson;
  late Future<List<QuestionModel>> _reviewedQuestions;

  @override
  void initState() {
    super.initState();
    _lesson = _curriculum.getLesson(
      subjectName: widget.subjectName,
      unitName: widget.unitName,
      lessonName: widget.lessonName,
    );
    if (widget.subjectName != null && widget.lessonName != null) {
      _reviewedQuestions = _questions.fetchForLesson(
        subject: widget.subjectName!,
        lesson: widget.lessonName!,
        chapter: widget.unitName,
        onlyFree: false,
      );
    } else {
      _reviewedQuestions = Future.value(const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مساحة الدرس')),
      body: FutureBuilder<CurriculumLesson?>(
        future: _lesson,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lesson = snapshot.data;
          if (snapshot.hasError || lesson == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 44),
                    const SizedBox(height: 10),
                    const Text('لم أتمكن من العثور على الدرس في الفهرس.'),
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

          final path = _studyPath(widget.subjectName ?? '');
          final example = _exampleFramework(widget.subjectName ?? '');
          final pitfalls = _commonPitfalls(widget.subjectName ?? '');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _LessonHero(
                subject: widget.subjectName ?? '',
                unit: widget.unitName ?? '',
                lesson: lesson.name,
              ),
              if (lesson.subtopics.isNotEmpty || _hasCatalogTopics(lesson.learningComponents)) ...[
                const SizedBox(height: 12),
                _CatalogTopicsCard(
                  subtopics: lesson.subtopics,
                  components: lesson.learningComponents,
                ),
              ],
              const SizedBox(height: 14),
              _SectionCard(
                icon: Icons.menu_book_rounded,
                title: 'ملخص الدرس من الكتاب',
                child: const _PendingContent(
                  message:
                      'لم يُعتمد ملخص هذا الدرس بعد على نسخة الكتاب الرسمية المطابقة لعام 2026–2027. لن نكتب ملخصًا من الذاكرة حتى لا نعلّمك معلومة غير دقيقة.',
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.route_rounded,
                title: 'طريقة مذاكرة هذا النوع من الدروس',
                child: Column(
                  children: path.asMap().entries.map((entry) {
                    return _StepRow(
                      number: entry.key + 1,
                      text: entry.value,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'كيف نعرض المثال المحلول؟',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سيُختار المثال من الدرس نفسه، ثم يُشرح دون القفز فوق الخطوات:',
                      style: TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    ...example.asMap().entries.map((entry) => _StepRow(
                          number: entry.key + 1,
                          text: entry.value,
                        )),
                    const SizedBox(height: 8),
                    const _PendingContent(
                      message:
                          'المثال الخاص بهذا الدرس لم يُعتمد بعد. هذا ترتيب لطريقة الشرح وليس مسألة من الكتاب.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                icon: Icons.warning_amber_rounded,
                title: 'أخطاء دراسية ننتبه لها',
                child: Column(
                  children: pitfalls
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.remove_circle_outline,
                                  color: Color(0xFFD18A22),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item, style: const TextStyle(height: 1.5))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<QuestionModel>>(
                future: _reviewedQuestions,
                builder: (context, questionSnapshot) {
                  final count = questionSnapshot.data?.where((question) => const {'mcq', 'single_choice', 'true_false', 'fill_blank', 'short_answer'}.contains(question.type.toLowerCase())).length ?? 0;
                  return _QuestionStatusCard(
                    count: count,
                    loading: questionSnapshot.connectionState == ConnectionState.waiting,
                    onStart: count == 0
                        ? null
                        : () => context.push(_testRoute()),
                  );
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.go('/subjects'),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('العودة إلى المواد'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasCatalogTopics(Map<String, dynamic> components) {
    return components.values.any((value) => value is String || value is List);
  }

  String _testRoute() {
    final query = Uri(queryParameters: {
      'subject': widget.subjectName ?? '',
      'lesson': widget.lessonName ?? '',
      'unit': widget.unitName ?? '',
    }).query;
    return '/test?$query';
  }

  List<String> _studyPath(String subject) {
    if (subject.contains('رياضيات')) {
      return const [
        'اكتب التعريف أو النظرية وشروط استعمالها قبل البدء.',
        'تابع مثال الكتاب سطرًا سطرًا، وحدد سبب كل خطوة.',
        'أعد الحل وحدك دون النظر إلى المثال.',
        'تحقق من النتيجة ومن الشروط والوحدات إن وجدت.',
      ];
    }
    if (subject.contains('فيزياء')) {
      return const [
        'حدد الكميات المعطاة والمطلوب بدقة.',
        'وحّد الوحدات وارسم مخططًا عندما يساعد ذلك.',
        'اختر العلاقة المناسبة واذكر سبب اختيارها.',
        'عوّض واحسب ثم افحص الوحدة واتجاه النتيجة.',
      ];
    }
    if (subject.contains('كيمياء')) {
      return const [
        'افهم الفكرة أو التفاعل قبل حفظ الصيغة.',
        'اكتب الرموز والمعادلات بوضوح ووازنها عند الحاجة.',
        'سجل الشروط والوحدات المستخدمة في كل مسألة.',
        'راجع منطق الناتج ومدى توافقه مع السؤال.',
      ];
    }
    if (subject.contains('أحياء')) {
      return const [
        'ابدأ بفهم المصطلحات وأجزاء البنية المدروسة.',
        'اربط كل جزء بوظيفته بدل حفظ الأسماء منفصلة.',
        'رتّب المراحل أو العمليات في مخطط واضح.',
        'قارن بين المفاهيم المتشابهة وراجع الرسم من الكتاب.',
      ];
    }
    if (subject.contains('إسلامية')) {
      return const [
        'اقرأ النص أو الدليل كما ورد في الكتاب.',
        'افهم المفردات والمعنى العام قبل حفظ التفاصيل.',
        'استخرج الفكرة والقيمة أو الحكم الذي يشرحه الدرس.',
        'اربط الإجابة بالدليل ولا تنسب نصًا غير متحقق منه.',
      ];
    }
    if (subject.contains('إنجليزية') || subject.contains('فرنسية')) {
      return const [
        'اقرأ النص أولًا لفهم الفكرة العامة.',
        'سجل المفردات الجديدة مع جملة توضح استعمالها.',
        'راجع القاعدة ضمن سياق الجملة لا كتعريف منفصل.',
        'استخدم ما تعلمته في كتابة أو إجابة قصيرة.',
      ];
    }
    return const [
      'اقرأ الدرس كاملًا مرة أولى لتكوين فكرة عامة.',
      'حدد الفكرة الرئيسة والكلمات أو المصطلحات الأساسية.',
      'دوّن النقاط المهمة بأسلوبك مع الرجوع إلى الكتاب.',
      'أغلق الكتاب واشرح الفكرة لنفسك ثم راجع ما نسيته.',
    ];
  }

  List<String> _exampleFramework(String subject) {
    if (subject.contains('رياضيات') ||
        subject.contains('فيزياء') ||
        subject.contains('كيمياء')) {
      return const [
        'المعطيات: ما المعلومات الموجودة في السؤال؟',
        'المطلوب: ما الكمية أو النتيجة التي نبحث عنها؟',
        'القانون: ما العلاقة وشروط تطبيقها؟',
        'التعويض والحساب: خطوة واضحة في كل سطر.',
        'التحقق: هل النتيجة منطقية والوحدة صحيحة؟',
      ];
    }
    if (subject.contains('أحياء')) {
      return const [
        'تحديد البنية أو العملية التي يتناولها المثال.',
        'شرح المكوّنات أو المراحل بالترتيب.',
        'ربط كل مرحلة بوظيفتها أو نتيجتها.',
        'تلخيص العلاقة في مخطط أو جدول عند ملاءمته.',
      ];
    }
    if (subject.contains('عربية')) {
      return const [
        'تحديد موضوع النص والفكرة الرئيسة.',
        'تقسيم النص إلى أفكار فرعية بحسب المعنى.',
        'الاستشهاد من النص عند طلب الدليل.',
        'تفسير الشاهد وربطه بالسؤال دون الخروج عن النص.',
      ];
    }
    return const [
      'فهم المطلوب من السؤال وتحديد كلمات المفتاح.',
      'اختيار القاعدة أو الفكرة المناسبة من الدرس.',
      'تطبيقها على المثال خطوة بخطوة.',
      'مراجعة الإجابة للتأكد من أنها أجابت عن المطلوب.',
    ];
  }

  List<String> _commonPitfalls(String subject) {
    if (subject.contains('رياضيات')) {
      return const [
        'استعمال قانون دون التحقق من شروطه.',
        'حذف خطوة جبرية تجعل الحل صعب المراجعة.',
        'الخلط بين النتيجة النهائية وطريقة الوصول إليها.',
      ];
    }
    if (subject.contains('فيزياء') || subject.contains('كيمياء')) {
      return const [
        'نسيان تحويل الوحدات أو كتابتها في الناتج.',
        'التعويض قبل ترتيب المعطيات وتحديد المطلوب.',
        'إهمال شروط العلاقة أو شروط التفاعل.',
      ];
    }
    if (subject.contains('أحياء')) {
      return const [
        'حفظ أسماء الأجزاء دون فهم وظيفة كل جزء.',
        'تغيير ترتيب المراحل في العملية الحيوية.',
        'الخلط بين مصطلحين متقاربين دون مقارنة دقيقة.',
      ];
    }
    if (subject.contains('عربية')) {
      return const [
        'كتابة الفكرة العامة بدل الإجابة عن المطلوب المحدد.',
        'ذكر شاهد دون تفسير علاقته بالفكرة.',
        'حفظ التحليل دون فهم دلالة النص.',
      ];
    }
    return const [
      'حفظ الإجابة دون فهم معناها أو سياقها.',
      'إغفال كلمة أساسية في صيغة السؤال.',
      'كتابة معلومات صحيحة لكنها لا تجيب عن المطلوب.',
    ];
  }
}

class _CatalogTopicsCard extends StatelessWidget {
  final List<String> subtopics;
  final Map<String, dynamic> components;
  const _CatalogTopicsCard({required this.subtopics, required this.components});

  static const Map<String, String> _labels = {
    'reading': 'القراءة',
    'writing': 'الكتابة',
    'vocabulary': 'المفردات',
    'grammar': 'القواعد',
    'pronunciation': 'اللفظ',
    'everyday_english': 'التعبير اليومي',
    'everyday_french': 'التعبير اليومي',
    'skills': 'المهارات',
    'listening': 'الاستماع',
    'speaking': 'المحادثة',
  };

  @override
  Widget build(BuildContext context) {
    final visible = components.entries.where((entry) =>
        entry.value is String || entry.value is List).toList(growable: false);
    return _SectionCard(
      icon: Icons.topic_outlined,
      title: 'محاور الدرس في الفهرس',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...subtopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 7, color: Color(0xFF1769E8)),
                    const SizedBox(width: 9),
                    Expanded(child: Text(topic)),
                  ],
                ),
              )),
          ...visible.map((entry) {
            final value = entry.value is List
                ? (entry.value as List).join('، ')
                : entry.value.toString();
            final label = _labels[entry.key] ?? entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 95,
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1769E8))),
                  ),
                  Expanded(child: Text(value, style: const TextStyle(height: 1.5))),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'هذه محاور الفهرس فقط؛ لا تُعد شرحًا أو ملخصًا معتمدًا للدرس.',
            style: TextStyle(color: Color(0xFF718096), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LessonHero extends StatelessWidget {
  final String subject;
  final String unit;
  final String lesson;
  const _LessonHero({required this.subject, required this.unit, required this.lesson});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF102E54), Color(0xFF1769E8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(color: Color(0xFFD8E8FF), fontSize: 12)),
            const SizedBox(height: 8),
            Text(lesson, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, height: 1.45)),
            const SizedBox(height: 8),
            Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12)),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _HeroPill(label: 'افهم'),
                _HeroPill(label: 'طبّق'),
                _HeroPill(label: 'تدرّب'),
              ],
            ),
          ],
        ),
      );
}

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1769E8)),
                  const SizedBox(width: 9),
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _PendingContent extends StatelessWidget {
  final String message;
  const _PendingContent({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF3DFB8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fact_check_outlined, color: Color(0xFFB57917), size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(message, style: const TextStyle(height: 1.6, fontSize: 12))),
          ],
        ),
      );
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFEAF2FF),
              child: Text('$number', style: const TextStyle(color: Color(0xFF1769E8), fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: const TextStyle(height: 1.55))),
          ],
        ),
      );
}

class _QuestionStatusCard extends StatelessWidget {
  final int count;
  final bool loading;
  final VoidCallback? onStart;
  const _QuestionStatusCard({required this.count, required this.loading, required this.onStart});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.quiz_outlined, color: Color(0xFF1769E8)),
                  SizedBox(width: 9),
                  Text('تدريب الدرس', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              if (loading)
                const LinearProgressIndicator()
              else if (count == 0)
                const _PendingContent(
                  message:
                      'لا توجد أسئلة منشورة ومعتمدة لهذا الدرس حتى الآن. توجد مسودات قيد المراجعة، لكنها مخفية عن الطالب ولن نعرضها قبل تدقيق الإجابات والمصادر.',
                )
              else ...[
                Text('$count سؤالًا متاحًا بعد المراجعة.', style: const TextStyle(height: 1.5)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('ابدأ التدريب'),
                ),
              ],
            ],
          ),
        ),
      );
}
