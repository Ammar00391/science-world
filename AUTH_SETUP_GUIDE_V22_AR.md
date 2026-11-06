# إعداد المصادقة في Supabase — Science World V22

هذا الدليل يكمل إعداد Flutter؛ لا يستطيع ملف ZIP وحده تغيير إعدادات مشروع Supabase الحي.

## 1. تحديث قاعدة البيانات الحالية

إذا سبق تشغيل `supabase/schema.sql` في مشروع V21، شغّل مرة واحدة ملف الترحيل:

`supabase/migrations/20261105_auth_profile_phone.sql`

الترحيل يضيف `profiles.phone`، ويعبّئ الأرقام القديمة من بيانات Auth Metadata عند وجودها، ويحدّث trigger إنشاء الملف الشخصي. وهو قابل لإعادة التشغيل.

للمشروع الجديد من الصفر، استخدم نسخة `supabase/schema.sql` المحدثة الموجودة في هذا الإصدار؛ لا حاجة لتشغيل ملف الترحيل بعدها.

## 2. إعداد البريد الإلكتروني

من Supabase Dashboard:

1. افتح **Authentication → Sign In / Providers → Email** وتأكد من تفعيل Email provider.
2. اختر سياسة تأكيد البريد المناسبة. عند تفعيل التأكيد، لا ينتقل التسجيل إلى التطبيق حتى يتم تأكيد البريد.
3. اضبط SMTP موثوقًا للإنتاج، واختبر وصول الرسائل ومجلد الرسائل غير المرغوب فيها.
4. شاشة التأكيد الحالية تقبل رمز OTP من 6 أرقام. إن اخترت قالب الرمز، استخدم متغير Supabase `{{ .Token }}` في قالب Confirm signup. كما أن رابط التأكيد يدعم العودة إلى التطبيق عبر رابط إعادة التوجيه أدناه.

## 3. روابط العودة إلى Android

من **Authentication → URL Configuration → Redirect URLs** أضف الرابطين التاليين كما هما:

- `scienceworld://login-callback/`
- `scienceworld://reset-password/`

أُضيفت intent filters لهذين المضيفين في AndroidManifest. لاختبار الرابط على Android يجب تثبيت التطبيق على الجهاز أو المحاكي. Google OAuth يتطلب أيضًا تسجيل redirect URL الخاص بـ Supabase لدى Google، وإكمال بيانات OAuth في Supabase.

## 4. اختبار الدورة

1. أنشئ حسابًا جديدًا باستخدام اسم ورقم هاتف وبريد غير مستخدم.
2. تأكد من وصول رسالة التأكيد، ثم أدخل رمز OTP أو افتح رابط التأكيد.
3. تحقق من ظهور المستخدم في **Authentication → Users** ومن صفه في `public.profiles` مع `display_name` و`phone` ورقم الطالب.
4. سجّل الخروج ثم اختبر تسجيل الدخول بالبريد وكلمة المرور.
5. من شاشة الدخول اختر «نسيت كلمة المرور؟»، وافتح رابط الرسالة على الجهاز نفسه، ثم احفظ كلمة مرور جديدة.
6. أغلق التطبيق وافتحه مجددًا؛ يجب أن يذهب المستخدم ذو الجلسة المحفوظة إلى الصفحة الرئيسية، والمستخدم غير المسجل إلى شاشة المقدمة.

## 5. البناء محليًا

مرّر بيانات الاتصال العامة عبر `--dart-define` عند البناء عند الحاجة. لا تضع `service_role` أو Secret key في Flutter أو APK أو المستودع.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release \\
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \\
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

لم يتم اختبار SMTP أو OAuth أو روابط البريد على مشروع حي ضمن بيئة إعداد ملفات المصدر. نجاح الكود محليًا لا يثبت اكتمال إعداد مزوّد البريد أو OAuth في لوحة Supabase.
