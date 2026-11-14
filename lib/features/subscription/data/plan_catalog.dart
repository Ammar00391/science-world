/// Subscription catalog and client-side feature map.
/// Server-side authorization remains authoritative for protected data/actions.
enum SubscriptionTier { free, silver, gold }

/// Client-side quota reference for display and tests. Supabase remains
/// authoritative and enforces the same rule before returning question data.
class QuestionQuotaPolicy {
  static const int targetQuestionsPerLesson = 40;
  static const int freeQuestionsPerLesson = 3;
  static const int silverQuestionsPerLesson = 6;

  static int questionLimit(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return freeQuestionsPerLesson;
      case SubscriptionTier.silver:
        return silverQuestionsPerLesson;
      case SubscriptionTier.gold:
        return targetQuestionsPerLesson;
    }
  }

  /// For Free/Silver, positionWithinLesson is the rank in its free or paid
  /// group. Silver receives the first three questions from each group.
  static bool canAccessQuestion({
    required SubscriptionTier tier,
    required bool isPaid,
    required int positionWithinLesson,
  }) {
    if (positionWithinLesson < 1) return false;
    switch (tier) {
      case SubscriptionTier.free:
        return !isPaid && positionWithinLesson <= freeQuestionsPerLesson;
      case SubscriptionTier.silver:
        return positionWithinLesson <= freeQuestionsPerLesson;
      case SubscriptionTier.gold:
        return positionWithinLesson <= targetQuestionsPerLesson;
    }
  }
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final int? priceSyp;
  final int? durationDays;
  final String durationLabel;
  final String tagline;
  final List<String> features;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.priceSyp,
    required this.durationDays,
    required this.durationLabel,
    required this.tagline,
    required this.features,
  });

  // Price intentionally remains unset until the owner confirms it.
  bool get isConfigured => tier == SubscriptionTier.free ||
      (priceSyp != null && priceSyp! > 0 && durationDays != null && durationDays! > 0);
}

class PlanCatalog {
  static const free = SubscriptionPlan(
    tier: SubscriptionTier.free,
    name: 'مجاني',
    priceSyp: 0,
    durationDays: 0,
    durationLabel: 'دائم',
    tagline: 'ابدأ رحلتك العلمية',
    features: [
      'الكتب والمحتوى المنشور مجانًا',
      '3 أسئلة من كل درس عند اعتماد ونشر محتوى المادة',
      'مؤقت الدراسة الهادئ',
      'النقاط والإنجازات الأساسية',
    ],
  );

  static const silver = SubscriptionPlan(
    tier: SubscriptionTier.silver,
    name: 'فضي',
    priceSyp: null,
    durationDays: 30,
    durationLabel: '30 يومًا',
    tagline: 'مزايا إضافية للمراجعة اليومية',
    features: [
      'كل مزايا المجاني',
      'فتح 6 أسئلة من كل درس (3 مجانية + 3 إضافية)',
      'ملخصات الدروس والأمثلة المحلولة المنشورة',
      'تنزيل المواد المشمولة بالباقة للعمل دون إنترنت',
      'حفظ تقدم الدراسة واستكمال الاختبارات',
      'مراجعة الأخطاء والإجابات السابقة',
      'تحليل أداء أساسي ونقاط قوة وضعف مختصرة',
      'خطة مراجعة أساسية وبطاقات ذاكرة',
      'دفتر القوانين والتعريفات',
      'البحث داخل ملفات PDF المحمّلة',
      'إظهار الإجابة والشرح والتلميحات',
      'حفظ الأسئلة المفضلة وسجل المحاولات',
      'إعادة حل الأسئلة الخاطئة وأدوات مساعدة أثناء الاختبار',
      'شارة فضية مميزة',
    ],
  );

  static const gold = SubscriptionPlan(
    tier: SubscriptionTier.gold,
    name: 'ذهبي VIP',
    priceSyp: null,
    durationDays: 75,
    durationLabel: '75 يومًا',
    tagline: 'كل المحتوى وأقوى أدوات التفوق',
    features: [
      'جميع مزايا الفضي، وفتح حتى 40 سؤالًا من كل درس',
      'جميع ملخصات الدروس والأمثلة المحلولة والمواد التسع المنشورة',
      'تنزيل كامل المواد المتاحة للعمل دون إنترنت',
      'مدرس ذكاء اصطناعي خاص لكل مادة',
      'شرح الدرس بأكثر من طريقة وتبسيط المفاهيم الصعبة',
      'حل المسائل خطوة بخطوة وتحليل صور المسائل والتمارين',
      'إنشاء أسئلة من الدرس وتدريبات علاجية للأخطاء',
      'اختبار شفهي تفاعلي',
      'خطة دراسة يومية ذكية وجدول يتكيف مع مستوى الطالب',
      'تحليل متقدم للقوة والضعف وتحديد الدروس التي تحتاج مراجعة',
      'مؤشر تقديري للاستعداد للامتحان مع توضيح أنه ليس ضمانًا للنتيجة',
      'مراجعة متباعدة وسجل أسبوعي ومقارنة الأداء السابق',
      'محاكاة الامتحان الوزاري بمؤقت وتصحيح وتقرير مفصل',
      'اختبارات شاملة ومخصصة حسب الوقت والصعوبة',
      'اختبارات عشوائية وإعادة الأسئلة الخاطئة',
      'واجهة ذهبية وشارة VIP وتخصيص ألوان التطبيق',
      'دفتر قوانين وتعريفات ودفتر ملاحظات لكل مادة',
      'حفظ المفضلة ومجلدات شخصية وبحث متقدم',
      'إشعارات مراجعة ذكية ومزامنة سحابية للتقدم',
      'مركز إنجازات وأوسمة وتحديات أسبوعية وسلسلة دراسة',
      'شهادات إنجاز داخل التطبيق وإحصائيات ساعات الدراسة',
      'أهداف يومية وشهرية',
    ],
  );

  static const all = [free, silver, gold];
}

/// Keys are intentionally explicit and fail closed. This is a UI convenience;
/// protected APIs and question payloads must enforce the same policy server-side.
class PremiumFeatureAccess {
  static const silverFeatures = <String>{
    'silver_extra_questions',
    'answer_reveal',
    'detailed_question_explanations',
    'question_hints',
    'attempt_history',
    'performance_statistics',
    'retry_wrong_answers',
    'exam_assistance',
    'lesson_summaries',
    'worked_examples',
    'limited_offline_downloads',
    'resume_tests',
    'mistake_review_basic',
    'basic_weakness_analysis',
    'basic_study_plan',
    'formula_notebook',
    'spaced_review_basic',
    'offline_pdf_search',
    'silver_badge',
  };

  static const goldFeatures = <String>{
    'unlimited_questions',
    'all_tests',
    'all_subject_downloads',
    'ai_tutor',
    'multi_style_explanations',
    'photo_solver',
    'step_by_step_solver',
    'lesson_question_generator',
    'remedial_practice',
    'oral_ai_exam',
    'smart_daily_plan',
    'adaptive_timetable',
    'advanced_weakness_analysis',
    'readiness_estimate',
    'spaced_review_advanced',
    'weekly_progress_report',
    'progress_comparison',
    'ministry_exam_simulation',
    'custom_exam_generator',
    'randomized_exams',
    'wrong_answer_retake',
    'gold_theme',
    'vip_badge',
    'theme_customization',
    'subject_notes',
    'advanced_formula_notebook',
    'personal_folders',
    'advanced_search',
    'smart_review_notifications',
    'cloud_progress_sync',
    'achievement_center',
    'weekly_challenges',
    'study_streak',
    'achievement_certificates',
    'study_time_statistics',
    'daily_monthly_goals',
    'favorites',
    // Earlier planned gold capabilities retained for compatibility.
    'written_step_checker',
    'lesson_audio',
    'virtual_labs',
    'intensive_study_plan',
  };

  static bool allows(SubscriptionTier tier, String featureKey) {
    if (goldFeatures.contains(featureKey)) return tier == SubscriptionTier.gold;
    if (silverFeatures.contains(featureKey)) {
      return tier == SubscriptionTier.silver || tier == SubscriptionTier.gold;
    }
    return false;
  }
}
