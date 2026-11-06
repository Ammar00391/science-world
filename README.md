# عالم العلوم | Science World – V24 (Learning First)

تحديث تعليمي يربط فهرس المواد والوحدات والدروس، ويضيف مساحة تعلم وتدريب بمؤقت ونتيجة. يحافظ على سياسة أسئلة آمنة: لا تظهر أي مسودة غير مراجعة للطلاب.

## تحديث V21 — نظام التعلم والأسئلة

- ادخل إلى المواد ثم الوحدة ثم الدرس.
- البنك النشط لا يحتوي أسئلة معتمدة بعد؛ المسودات محفوظة خارج Assets ولا تظهر للطلاب.
- سجل الاختبارات في هذا الإصدار محلي على الجهاز، وليس مزامنة سحابية.
- صفحة الدرس تعرض مسار مذاكرة متكيفًا مع نوع المادة، وتفصل بين الإرشاد العام وبين الملخص/المثال الذي لم يُعتمد من نسخة الكتاب.
- التدريب يعرض الأسئلة التي تحمل حالة `approved` أو `published` فقط.
- الهدف الافتراضي 32 سؤالًا (6 مجانية و26 للمشتركين)، ويمكن الزيادة للمواد الحسابية عند الحاجة دون تكرار.
- راجع `docs/QUALITY_FIRST_QUESTION_POLICY_AR.md` و`docs/LEARNING_FLOW_V21_AR.md`.
- تحقق من ملفات البنك قبل الاعتماد: `python scripts/validate_question_bank.py content_seed/question_banks/arabic_unit1_lesson1_free_draft.json`.

## Supabase — مهم

1. افتح مشروع Supabase الجديد الصحيح.
2. من SQL Editor افتح New query.
3. انسخ محتوى `supabase/schema.sql` كاملًا والصقه ثم اضغط Run مرة واحدة.
4. تأكد من ظهور الجداول المذكورة في آخر السكربت دون أي خطأ.

**لا تشغّل** `questions_schema.sql` أو `subscriptions_schema.sql` أو ملفات `functions/*.sql` أو migrations القديمة منفصلة؛ تم دمج ما يلزم منها في `supabase/schema.sql` لتجنب ترتيب خاطئ أو سياسات متعارضة. ملفات SQL القديمة أصبحت تنبيهات غير تنفيذية.

### ما الذي يجهزه السكربت؟
- profiles مع رقم طالب ثابت ينشأ من الخادم.
- books وحقول PDF التي يقرأها Flutter.
- questions وquestion_versions وquestion_tags.
- subscriptions وactivation_codes وactivation_logs وpayment_requests.
- exam_attempts الذي تقرؤه صفحة التقدم الحالية.
- سياسات RLS: المحتوى المجاني المنشور متاح للمستخدم المسجل، والمحتوى المدفوع يتطلب اشتراكًا فعالًا.
- RPC آمنة للأسئلة وتفعيل رموز الاشتراك.

السكربت لا يضيف محتوى تجريبيًا، ولا ينشئ رمز اشتراك خاصًا، ولا ينشئ مستخدم مدير.

## مفاتيح الاتصال

يستخدم Flutter رابط المشروع ومفتاح `Publishable` فقط عبر `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY`. لا تضع `Secret key` أو `service_role` في Dart أو APK أو `--dart-define`. مفتاح Publishable مصمم للعميل؛ حماية البيانات تعتمد على RLS وسياسات SQL.

## ما يحتاج إعدادًا منفصلًا بعد قاعدة البيانات

- Auth: تفعيل تأكيد البريد وضبط قالب الرسالة وSMTP قبل اختبار إرسال الرسائل.
- Google OAuth: إضافة بيانات Google Cloud وتسجيل Redirect URL الذي يستخدمه التطبيق داخل Supabase.
- Storage: إنشاء bucket خاص للكتب والمرفقات، ثم إعداد سياسات القراءة والتنزيل قبل رفع ملفات PDF.
- AI: نشر مجلد `supabase/functions/ai-chat` بعد ضبط `OPENAI_API_KEY` و`SUPABASE_PUBLISHABLE_KEY` ضمن Function Secrets. لا تضع هذه الأسرار داخل Flutter أو GitHub.
- الاشتراكات: توليد أكواد hash من جهة موثوقة فقط. لا تستخدم أي رمز قديم منشور في ملفات أو نسخ سابقة.

## Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

## حدود التحقق

نجاح تشغيل SQL لا يعني أن SMTP أو Google OAuth أو Storage أو AI أو الدفع قد تم إعدادها. يجب اختبار هذه الخدمات كلٌّ على حدة قبل إعلان جاهزية التطبيق.


## تحديث V22 — المصادقة والحسابات

- تسجيل حساب الطالب بالاسم الكامل ورقم الهاتف والبريد وكلمة المرور.
- تأكيد البريد برمز OTP أو رابط التأكيد، مع دعم إعادة إرسال الرمز.
- تسجيل الدخول وتسجيل الخروج، واستعادة كلمة المرور وتعيين كلمة مرور جديدة عبر رابط التطبيق.
- يوجّه Splash المستخدم صاحب الجلسة المحفوظة إلى الصفحة الرئيسية، وغير المسجل إلى شاشة المقدمة.
- يتم حفظ الاسم ورقم الهاتف ضمن Auth Metadata وإنشاء ملف الطالب تلقائيًا عبر trigger قاعدة البيانات.
- راجع `AUTH_SETUP_GUIDE_V22_AR.md` قبل اختبار البريد أو OAuth. على قاعدة V21 الحالية شغّل `supabase/migrations/20261105_auth_profile_phone.sql` مرة واحدة.


## تحديث V23 — واجهة دخول موحدة والمواد الدراسية

- إضافة شاشة `AuthScreen` موحدة بتبويبي تسجيل الدخول وإنشاء الحساب، مع Google OAuth واستعادة كلمة المرور والتحقق من المدخلات.
- جعل شاشة البداية تفتح واجهة المصادقة الموحدة مع الإبقاء على مسارات الدخول والتسجيل القديمة للتوافق.
- تحسين شاشة المواد لتعرض بيانات جدول `subjects` عند توفر جداول المحتوى القديمة في Supabase، وتستخدم فهرس المناهج المحلي عند غياب الجدول أو تعذر الوصول إليه.
- ربط المواد القادمة من Supabase بمسار الوحدات، ودعم حقلي `title` و`name` في سجلات الوحدات والدروس.
- راجع `V23_AUTH_AND_SUBJECTS_REPORT_AR.md` لملاحظات التوافق وحدود الاختبار.


## تحديث V24 — توحيد النسخ ومعالجة أخطاء المكتبات

- دمج `ActivationScreen` القديمة مع شاشة التفعيل الأساسية لمنع اختلاف RPC بين النسخ.
- تحسين تحميل وحدات المادة ودروسها من جداول Supabase القديمة، مع دعم `unit_order` و`order_index` وإظهار أخطاء الجداول وRLS بوضوح.
- الإبقاء على Google OAuth من خلال Supabase دون إضافة `google_sign_in` غير المستخدم.
- فحص الاستيرادات المحلية والحزم ومسارات الأصول، وتنظيف النسخ التاريخية المتداخلة من أرشيف التسليم.
- توحيد متطلبات SDK مع ملف القفل: Dart 3.13.0 أو أحدث وFlutter 3.47.0 أو أحدث.
- راجع `LIBRARY_NOT_FOUND_FIX_AR.md` لفتح المجلد الصحيح وتشغيل أوامر استعادة الحزم والتحليل والاختبارات.
- راجع `V24_LIBRARY_IMPORT_AND_MERGE_REPORT_AR.md` لتفاصيل الملفات والتكامل وحدود التحقق.

### تجهيز المشروع بعد فك الضغط

افتح Terminal من المجلد الذي يحتوي على `pubspec.yaml`، ثم نفّذ:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

أو شغّل `prepare_flutter_project.bat` على Windows أو `prepare_flutter_project.sh` على macOS/Linux.

**تنبيه:** لم يتم بناء APK في بيئة إعداد الأرشيف لعدم توفر Flutter/Dart SDK فيها. كما أن Google OAuth وإعداد الجداول وسياسات RLS تحتاج إعدادًا واختبارًا في مشروع Supabase الحي.


## تحديث V24.1 — Codemagic Android Release

- إضافة `codemagic.yaml` إلى جذر المشروع لبناء APK وAAB بوضع Release.
- قراءة `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY` من مجموعة Codemagic باسم `supabase_credentials` وتمريرهما إلى Flutter عبر `--dart-define`.
- ربط التوقيع بمفتاح Android مرفوع إلى Codemagic تحت المرجع `science_world_upload_keystore`، ومنع بناء CI Release عند غياب مفتاح التوقيع.
- إضافة مشغّل Gradle متوافق مع Gradle 8.14.1 المتوفر في صورة Codemagic macOS. راجع `CODEMAGIC_SETUP_AR.md` قبل أول بناء.
- راجع `V24_CODEMAGIC_UPDATE_REPORT_AR.md` لمعرفة ما تم التحقق منه وما يحتاج إعدادًا من حسابك.
