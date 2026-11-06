# إعداد Codemagic لمشروع Science World V24

أضيف ملف `codemagic.yaml` إلى جذر المشروع بجانب `pubspec.yaml`، وضُبط لبناء ملفي Android Release: ‏`.aab` و`.apk`.

## 1) متغيرات Supabase

في Codemagic افتح التطبيق ثم **Environment variables**، وأنشئ مجموعة اسمها تماماً:

`supabase_credentials`

أضف داخلها:

| الاسم | القيمة |
|---|---|
| `SUPABASE_URL` | عنوان مشروع Supabase الذي يبدأ بـ `https://` |
| `SUPABASE_PUBLISHABLE_KEY` | مفتاح Supabase Publishable الذي يبدأ بـ `sb_publishable_` |

يمكن تفعيل خيار Secret في لوحة Codemagic لإخفاء القيمة في السجلات. المفتاح المناسب لتطبيق Flutter هو Publishable/Anon فقط. **لا تضع `service_role` أو أي Secret key داخل التطبيق أو متغيرات Dart.**

## 2) توقيع Android Release

الملف مضبوط ليستعمل مرجع توقيع اسمه:

`science_world_upload_keystore`

في Codemagic افتح **Team settings → codemagic.yaml settings → Code signing identities → Android keystores**، ثم ارفع ملف keystore الذي تملكه، وأدخل كلمة مرور المخزن واسم المفتاح وكلمة مروره. اجعل **Reference name** مطابقاً تماماً للاسم أعلاه.

إذا سبق نشر التطبيق على Google Play، يجب إعادة استخدام مفتاح الرفع/التوقيع الصحيح نفسه؛ لا تنشئ مفتاحاً جديداً للتحديث قبل التأكد من سياسة App signing الحالية. احتفظ بنسخة آمنة من keystore وكلمات المرور خارج المستودع.

تم تعديل `android/app/build.gradle` لقراءة متغيرات `CM_KEYSTORE_*` التي يحقنها Codemagic. إذا غاب توقيع الإصدار في بيئة CI فسيفشل البناء برسالة واضحة بدلاً من إنتاج Release موقّع بمفتاح Debug.

## 3) تشغيل البناء

1. ارفع المشروع إلى مستودع Git (GitHub أو GitLab أو Bitbucket).
2. أضف المستودع إلى Codemagic.
3. تأكد أن Codemagic يكتشف `codemagic.yaml` من جذر المشروع.
4. شغّل workflow باسم **Science World Android Release**.
5. بعد نجاح البناء ستجد الملفات ضمن Artifacts:
   - `app-release.aab` للنشر على Google Play.
   - `app-release.apk` للتثبيت/التوزيع المباشر.

## 4) ملاحظات مهمة

- لا يوجد عنوان بريد افتراضي في إعداد النشر؛ لم تتم إضافة `user@example.com` لأنه عنوان توضيحي وليس عنواناً مؤكداً للمستخدم.
- Flutter SDK وAndroid SDK يتم تحديد مسارهما من متغيرات Codemagic المدمجة `FLUTTER_ROOT` و`ANDROID_SDK_ROOT`، وليس بافتراض أن Flutter موجود في `$HOME/flutter`.
- مجلد Android في الأرشيف الأصلي كان يفتقد `gradlew` و`gradlew.bat` وملف wrapper JAR؛ أُضيف مشغّل `android/gradlew` ليوجه أوامر Codemagic إلى Gradle 8.14.1 المثبت مسبقاً على صورة macOS، مع بديل `GRADLE_HOME` أو `gradle` في PATH محلياً. هذا المشغّل ليس ملف Gradle Wrapper القياسي ولا ينزّل Gradle بنفسه.
- لا يضع هذا الملف أي مفاتيح سرية في YAML أو في كود البناء. متغيرات Supabase تُمرر وقت البناء كـ `--dart-define`.
- لم ينفذ بناء فعلي على حساب Codemagic لأن ذلك يتطلب ربط المستودع وحسابك ورفع keystore وضبط متغيرات البيئة من طرفك.
