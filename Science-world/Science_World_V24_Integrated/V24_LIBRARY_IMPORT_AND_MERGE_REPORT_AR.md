# تقرير الدمج والإصلاح V24 — Science World

## ما تم فحصه

- فحصت أرشيف V23 وراجعت ملف `pubspec.yaml` وقائمة الحزم ومسارات `import` المحلية.
- لم أجد استيرادًا محليًا نشطًا يشير إلى ملف Dart غير موجود.
- جميع الحزم الخارجية التي يستوردها كود Dart الحالي موجودة في `dependencies` أو ضمن حزم Flutter الأساسية.
- الأرشيف السابق كان يجمع المشروع النشط مع إصدارات ومجلدات قديمة متعددة؛ أُزيلت النسخ التاريخية المتداخلة من حزمة التسليم حتى لا يفتح المستخدم مشروعًا قديمًا بالخطأ.
- لا يستورد المشروع `package:google_sign_in/google_sign_in.dart`؛ تسجيل Google يستخدم تدفق Supabase OAuth الموجود في `supabase_flutter`، لذلك لا يحتاج إضافة `google_sign_in` في هذا التصميم.

## ما تم دمجه وتحسينه

### 1. تسجيل الدخول وGoogle واستعادة كلمة المرور
- الإبقاء على شاشة `AuthScreen` الموحدة.
- الإبقاء على `AuthService` كطبقة واحدة للمصادقة.
- Google Sign-In يعمل بتدفق Supabase OAuth مع إعادة التوجيه `scienceworld://login-callback/`.
- أضيف فحص لنتيجة إطلاق صفحة OAuth؛ لم يعد فشل فتح التدفق يُعامل على أنه إطلاق ناجح.
- استعادة كلمة المرور وإعادة تعيينها موجودتان في `ResetPage` باستخدام `scienceworld://reset-password/`.
- AndroidManifest يتضمن مساري العودة السابقين.

### 2. تفعيل الاشتراك
- شاشة التفعيل الأساسية هي `lib/features/subscription/presentation/activation_code_page.dart`.
- خدمة RPC الوحيدة هي `lib/features/subscription/data/subscription_service.dart`.
- يبقى `lib/screens/activation_screen.dart` متاحًا للتوافق مع الأكواد القديمة، لكنه يعرض الشاشة الأساسية نفسها بدل تكرار التنفيذ.
- توقيع الدالة في `supabase/schema.sql` هو:
  `activate_subscription(p_user_id uuid, p_code text) returns boolean`
- لذلك يرسل التطبيق `p_user_id` من جلسة Supabase الحالية و`p_code`، ثم يتعامل مع الاستجابة على أنها `boolean`. لا تستبدل أسماء هذه المعاملات بـ `input_code` إلا بعد تعديل SQL المنشور ومراجعته.

### 3. المواد والوحدات والدروس
- شاشة المواد النشطة هي `lib/features/subjects/presentation/subjects_page.dart`.
- المواد تُحمّل من جدول `subjects` عند توفره، وإلا تستخدم فهرس المنهج المحلي.
- المواد القادمة من Supabase تنتقل إلى `UnitsScreen` عبر المسار `/database-units`.
- حسّنت `CurriculumService` ليدعم `unit_order` أو `order_index`، وكذلك `lesson_order` أو `order_index`، مع محاولة أخيرة دون ترتيب إذا لم يوجد أي عمود ترتيب.
- تقبل `UnitsScreen` معاملي الاسم القديم والجديد `subjectName` و`subjectTitle` حتى لا يفشل الاستدعاء بسبب اختلاف الاسم بين نسخ الواجهة.
- أُعيد تنظيم `UnitsScreen` لتخزين طلبات الدروس مؤقتًا داخل الشاشة، وإظهار أخطاء الجداول والصلاحيات بدل إخفائها كقائمة فارغة، مع دعم السحب للتحديث.
- لا يضيف ملف SQL الأساسي الحالي جداول `subjects` و`units` و`lessons`؛ لذلك يجب أن تكون هذه الجداول موجودة في مشروع Supabase الفعلي مع سياسات قراءة مناسبة، أو سيستخدم التطبيق فهرس المنهج المحلي.

## سبب رسالة Library not found وكيفية معالجتها

قد تشير الرسالة إلى أكثر من حالة، ولا يمكن تحديد سبب جهازك بدقة دون نص الخطأ الكامل. في النسخة المرفقة عالجت أسبابًا شائعة مرتبطة بالأرشيف والتكرار، وأضفت الخطوات التالية:

1. فك ضغط الملف وافتح مجلد `Science_World_V24_Integrated` مباشرة؛ يجب أن تجد `pubspec.yaml` و`lib/main.dart` في المجلد نفسه.
2. لا تفتح أي مجلد محفوظ من إصدار قديم أو ملف ZIP داخلي.
3. افتح Terminal داخل مجلد المشروع نفسه، ثم نفّذ:
   ```bash
   flutter --version
   flutter doctor -v
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```
4. يطلب ملف القفل الحالي Dart `3.13.0` أو أحدث وFlutter `3.47.0` أو أحدث. عُدّل `environment` ليعرض ذلك صراحةً بدل انتظار خطأ غير واضح من مدير الحزم.
5. لا تضف `import 'package:google_sign_in/google_sign_in.dart';` إلى هذه النسخة ما دمت تستخدم Supabase OAuth؛ هذا الاستيراد يحتاج حزمة غير مستخدمة هنا.
6. إذا كانت الرسالة حرفيًا `Library not found for -l...` من Xcode أو رابطًا أصليًا، فهذه ليست رسالة Dart import؛ يلزم نص الخطأ الكامل والمنصة لمعرفة المكتبة الأصلية المفقودة.

## إعداد Supabase المطلوب خارج ملفات Flutter

- في Supabase: فعّل Google ضمن Authentication Providers وأدخل OAuth Client ID وClient Secret الصحيحين من Google Cloud.
- أضف `scienceworld://login-callback/` و`scienceworld://reset-password/` إلى Redirect URLs المسموح بها.
- أضف عنوان callback الخاص بمشروع Supabase (`https://<project-ref>.supabase.co/auth/v1/callback`) في إعدادات OAuth لدى Google.
- اختبر التفعيل بحساب مسجل وكود صالح غير مستهلك. لا تضع Service Role Key أو Secret Key في Flutter.

## نتائج الفحص الساكن للنسخة الناتجة

- 89 ملف Dart بين التطبيق والاختبارات.
- 0 مسارات استيراد محلية مفقودة.
- 0 حزم خارجية مستوردة وغير معلنة.
- 0 حزم مباشرة معلنة في `pubspec.yaml` مفقودة من `pubspec.lock`.
- جميع ملفات JSON الستة قابلة للقراءة، وجميع الأصول والخطوط المعلنة في `pubspec.yaml` موجودة.
- نجح مدقق فهرس المنهج: 9 مواد و52 وحدة و237 درسًا من ناحية البنية فقط.
- نجح مدقق ملفّي بنك الأسئلة بنيويًا، لكنهما ما زالا مسودتين للمراجعة؛ ظهرت تحذيرات تمنع عرض أسئلتهما للطلاب قبل اعتماد المعلم.

## حدود التحقق

- تم إجراء فحص ساكن لمسارات الاستيراد المحلية، والحزم المستوردة، ومسارات الأصول المعلنة في `pubspec.yaml`.
- لم يكن Flutter أو Dart SDK مثبتًا في بيئة إعداد الأرشيف؛ لذلك لم أستطع تشغيل `flutter pub get` أو `flutter analyze` أو `flutter test` أو بناء APK فعليًا.
- لم يتم الاتصال بمشروع Supabase حي، ولم تُجرَ تغييرات على قاعدة البيانات أو استهلاك أكواد تفعيل حقيقية.
- نجاح الفحص الساكن لا يساوي تأكيد نجاح البناء على جهازك. إذا استمرت الرسالة، أرسل نص الخطأ كاملًا أو صورة شاشة منه مع توضيح هل تظهر على Android Studio أم عند تشغيل التطبيق أم عند بناء APK.
