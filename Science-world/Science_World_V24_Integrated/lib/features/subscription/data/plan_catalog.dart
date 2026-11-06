/// Product catalog for the app. Prices are in Syrian pounds (SYP) per plan period.
/// This catalog is presentation metadata only; server-side authorization is required
/// before serving any premium content.
enum SubscriptionTier { free, silver, gold }

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final int priceSyp;
  final int durationDays;
  final String durationLabel;
  final String tagline;
  final List<String> features;
  const SubscriptionPlan({required this.tier, required this.name, required this.priceSyp, required this.durationDays, required this.durationLabel, required this.tagline, required this.features});
}

class PlanCatalog {
  static const free = SubscriptionPlan(
    tier: SubscriptionTier.free, name: 'مجاني', priceSyp: 0, durationDays: 0, durationLabel: 'دائم',
    tagline: 'ابدأ رحلتك العلمية',
    features: ['الكتب والمحتوى المنشور مجانًا', 'أسئلة مجانية محدودة', 'مؤقت الدراسة الهادئ', 'النقاط والإنجازات الأساسية'],
  );
  static const silver = SubscriptionPlan(
    tier: SubscriptionTier.silver, name: 'فضي', priceSyp: 500, durationDays: 30, durationLabel: 'شهر واحد',
    tagline: 'أدوات يومية للمراجعة الذكية',
    features: ['كل مزايا المجاني', 'دفتر القوانين الذكي', 'بطاقات المراجعة والذاكرة', 'البحث داخل ملفات PDF المحمّلة', 'تحليل الأخطاء الأساسي', 'خطة مراجعة أساسية'],
  );
  static const gold = SubscriptionPlan(
    tier: SubscriptionTier.gold, name: 'ذهبي', priceSyp: 1000, durationDays: 75, durationLabel: 'شهران ونصف (75 يومًا)',
    tagline: 'كل المزايا لمدة شهرين ونصف',
    features: ['جميع مزايا الفضي والذهبي', 'جميع الأدوات التعليمية المدفوعة خلال مدة الاشتراك', 'المدرّس الذكي وحل الخطوات', 'حل المسائل من الصور', 'تصحيح خطوات الحل المكتوب', 'إنشاء امتحانات مخصصة', 'تحليل متقدم لنقاط الضعف', 'شرح الدروس صوتيًا', 'مختبرات علمية افتراضية', 'خطة مكثفة قبل الامتحان'],
  );
  static const all = [free, silver, gold];
}

class PremiumFeatureAccess {
  static const silverFeatures = <String>{'formula_notebook', 'spaced_review', 'offline_pdf_search', 'basic_weakness_analysis', 'basic_study_plan'};
  static const goldFeatures = <String>{'ai_tutor', 'photo_solver', 'written_step_checker', 'custom_exam_generator', 'advanced_weakness_analysis', 'lesson_audio', 'virtual_labs', 'intensive_study_plan'};

  static bool allows(SubscriptionTier tier, String featureKey) {
    if (silverFeatures.contains(featureKey)) return tier == SubscriptionTier.silver || tier == SubscriptionTier.gold;
    if (goldFeatures.contains(featureKey)) return tier == SubscriptionTier.gold;
    return true; // Free features remain available by default.
  }
}
