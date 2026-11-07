# إعداد Supabase الجديد — Science World V20

## بيانات الاتصال العامة
- Project URL: `https://faiituujosrsthdrsefw.supabase.co`
- Flutter يستخدم Publishable key فقط.
- لا تستخدم Secret key أو service_role في Flutter أو GitHub أو APK.

## ملف قاعدة البيانات الصحيح

استخدم ملفًا واحدًا فقط: `supabase/schema.sql`.

1. افتح لوحة Supabase للمشروع `Science World`.
2. افتح SQL Editor ثم New query.
3. الصق الملف كاملًا واضغط Run.
4. يجب أن ينتهي التنفيذ دون خطأ، وتظهر الجداول: `profiles`, `books`, `questions`, `question_versions`, `question_tags`, `activation_codes`, `subscriptions`, `activation_logs`, `payment_requests`, `exam_attempts`.

الملف مرتب حسب الاعتماديات: ينشئ `activation_codes` قبل `subscriptions`، ويجعل لكل مستخدم سجل اشتراك واحدًا حتى ينجح استعلام Flutter `maybeSingle()`. كما يزيل السياسات القديمة على جداول التطبيق المستهدفة قبل إنشاء سياسات RLS مضبوطة، حتى لا تسمح سياسة قديمة واسعة بتجاوز شرط الاشتراك.

**لا تشغّل ملفات SQL القديمة منفصلة**، بما فيها `questions_schema.sql`, `subscriptions_schema.sql`, `profile_enhancements.sql`, `functions/get_questions.sql`, `functions/activate_subscription.sql` أو ملفات migrations التاريخية. أصبحت هذه الملفات غير تنفيذية عمدًا.

## الأمان والسلوك الحالي
- المستخدم يقرأ ملفه الشخصي فقط ويعدّل الحقول المسموح بها.
- المستخدم لا يستطيع إنشاء اشتراك أو تعديل مدته من Flutter.
- المستخدم لا يستطيع قراءة جداول رموز التفعيل.
- تفعيل الرمز يتم عبر RPC تتحقق من أن `p_user_id` يساوي `auth.uid()`، وتقارن hash بالطريقة الصحيحة، وتقفل صف الرمز لمنع استخدامه بالتزامن، وتفرض حد محاولات.
- الكتب والأسئلة المدفوعة لا تظهر إلا لحساب لديه اشتراك `premium` فعال.
- الأسئلة ذات الحالة غير المنشورة لا تظهر للطلاب.
- طلبات الدفع ومحاولات الاختبار لا يمكن للمستخدم قراءة بيانات غيره.

## لا يزال يحتاج إعدادًا يدويًا
1. Auth → Email: تأكيد البريد، قالب OTP، وإعداد SMTP صالح.
2. Auth → URL Configuration: تأكد من الروابط المسموحة وروابط الاستعادة.
3. Google provider: يحتاج OAuth Client ID/Secret من Google Cloud وتسجيل callback في Supabase.
4. Storage: لم ننشئ bucket للكتب في هذه المرحلة؛ يجب تحديد سياسة خاصة قبل رفع PDF، خصوصًا الكتب المدفوعة.
5. Edge Function `ai-chat`: اضبط `OPENAI_API_KEY` و`SUPABASE_PUBLISHABLE_KEY` ضمن Function Secrets ثم انشر الدالة.
6. أكواد الاشتراك: لا يوجد رمز افتراضي أو رمز مالك مضمن. أنشئ الرموز من جهة موثوقة وخزّن hash فقط.

## Codemagic

يستخدم `codemagic.yaml` المتغيرين `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY`. الـ Publishable key ليس مفتاحًا سريًا، لكن لا تضف Secret key أو service_role إلى متغيرات Dart أو أوامر بناء APK.

## ملاحظات مهمة
- لا يضيف SQL أي كتب أو أسئلة وهمية؛ الجداول ستكون فارغة حتى تُدخل محتوى حقيقيًا.
- صفحة التقدم تقرأ `exam_attempts`، لكن التطبيق الحالي لا يملك بعد تدفق إرسال موثوقًا لتسجيل محاولات الاختبار؛ لذلك قد يظهر العدد صفرًا.
- صفحة الكتب تحتاج Storage وسياسة تنزيل متوافقة مع `file_url`.
- لا تعتبر Auth أو SMTP أو Google أو AI أو Storage مكتملة بمجرد تنفيذ SQL.
