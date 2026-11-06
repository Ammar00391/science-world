# تقرير تنفيذ V22 — المصادقة وإنشاء الحساب

## ما تم دمجه

- تطوير `AuthService` ليكون نقطة الدخول الموحدة لـ Supabase Auth.
- تسجيل حساب بالاسم الكامل ورقم الهاتف والبريد وكلمة المرور، مع حفظ `full_name` و`phone` في Auth Metadata وإرسال رابط تأكيد إلى URI التطبيق.
- تسجيل الدخول بالبريد وكلمة المرور مع تطبيع البريد والتحقق من المدخلات ورسائل عربية مفهومة.
- تدفق تأكيد البريد برمز OTP وإعادة إرسال الرمز (الشاشة والـ cooldown موجودان وتم الاحتفاظ بهما).
- استعادة كلمة المرور عبر رابط Deep Link، وإضافة شاشة تحديث كلمة المرور الجديدة بعد فتح الرابط.
- التقاط أحداث Supabase Auth داخل التطبيق لتوجيه رابط الاستعادة إلى نموذج كلمة المرور الجديدة.
- إضافة مسار `scienceworld://reset-password/` إلى Android، مع الحفاظ على `scienceworld://login-callback/` لـ OAuth/تأكيد البريد.
- تعديل Splash: المستخدم ذو جلسة محفوظة ينتقل إلى الصفحة الرئيسية؛ غير المسجل ينتقل إلى المقدمة.
- عرض رقم الهاتف ضمن الملف الشخصي من بيانات Auth Metadata.
- إضافة عمود `profiles.phone` في المخطط، وترحيل idempotent لقواعد V21 الحالية.
- إضافة اختبارات وحدات للتحقق من البريد والاسم والهاتف وكلمة المرور.
- رفع رقم إصدار التطبيق إلى `1.4.0+16`.

## ملفات رئيسية

- `lib/features/auth/data/auth_service.dart`
- `lib/features/auth/data/auth_input_validator.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/signup_page.dart`
- `lib/features/auth/presentation/verify_page.dart`
- `lib/features/auth/presentation/reset_page.dart`
- `lib/app/app.dart`
- `lib/features/splash/presentation/splash_page.dart`
- `android/app/src/main/AndroidManifest.xml`
- `supabase/schema.sql`
- `supabase/migrations/20261105_auth_profile_phone.sql`
- `test/auth_input_validator_test.dart`

## ما يجب تنفيذه من لوحة Supabase

- تشغيل الترحيل `supabase/migrations/20261105_auth_profile_phone.sql` مرة واحدة على قاعدة V21 الحالية. (للتثبيت الجديد استخدم schema.sql المحدث.)
- إضافة رابطَي redirect في Supabase URL Configuration.
- تهيئة Email provider وSMTP وقالب التأكيد.
- إعداد Google OAuth منفصلًا إن رغبت باختباره.

## التحقق والقيود

- تم فحص الربط والملفات نصيًا، والتحقق من وجود جميع ملفات الترحيل والتوجيه.
- Flutter/Dart SDK غير متوفر في بيئة تنفيذ الأرشيف، لذلك لم يمكن تشغيل `flutter analyze` أو `flutter test` أو بناء APK.
- لم يتم إرسال رسائل بريد حقيقية أو اختبار SMTP/OAuth على مشروع Supabase حي.
- ملف ZIP يضم كود Flutter وملفات SQL؛ لا ينفذ الترحيل تلقائيًا على قاعدة Supabase البعيدة.
