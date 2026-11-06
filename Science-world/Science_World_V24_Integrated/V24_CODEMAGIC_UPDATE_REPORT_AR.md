# تقرير تحديث Codemagic - Science World V24

## ما تم تحديثه

- إضافة/تحديث `codemagic.yaml` في جذر المشروع.
- استخدام مجموعة متغيرات `supabase_credentials`، ومتغيري `SUPABASE_URL` و`SUPABASE_PUBLISHABLE_KEY` بما يطابق `SupabaseConfig` داخل التطبيق.
- بناء AAB وAPK بوضع Release وتمرير إعدادات Supabase عبر `--dart-define`.
- إضافة مرجع توقيع Android في Codemagic باسم `science_world_upload_keystore`.
- تحديث Gradle في Android لقراءة متغيرات توقيع Codemagic `CM_KEYSTORE_PATH` و`CM_KEYSTORE_PASSWORD` و`CM_KEY_ALIAS` و`CM_KEY_PASSWORD`، ورفض بناء Release في CI عند غياب توقيع إصدار صحيح.
- إضافة `android/gradlew` متوافقاً مع صورة Codemagic macOS التي توفر Gradle 8.14.1، وإضافة launcher لنظام Windows يعتمد على Gradle المثبت محلياً.
- استبعاد ملفات التوقيع المحلية من Git عبر `.gitignore`.

## تحقق محلي

- تحليل YAML بواسطة PyYAML نجح.
- التأكد برمجياً من وجود workflow ومجموعة Supabase ومرجع التوقيع ومساري artifact للـ AAB وAPK نجح.
- لا يتوفر Flutter/Dart SDK أو Gradle في بيئة إعداد هذه الحزمة؛ لذلك لم يتم تنفيذ `flutter analyze` أو `flutter build` فعلياً.

## قبل أول بناء

يلزم إنشاء مجموعة `supabase_credentials` في Codemagic، وإضافة متغيري Supabase إليها، ورفع keystore داخل Code signing identities باسم reference مطابق تماماً لـ `science_world_upload_keystore`. لا يمكن تنفيذ هذه الخطوات دون الدخول إلى حساب Codemagic الخاص بصاحب المشروع.

## قيد مهم

`android/gradlew` هنا launcher مخصص لبيئات البناء، وليس Gradle Wrapper القياسي؛ فهو يستخدم Gradle 8.14.1 الموجود مسبقاً في Codemagic macOS (`~/programs/gradle-8.14.1`) أو `GRADLE_HOME`/`PATH` محلياً. يفضل لاحقاً استبداله بالملفات القياسية التي يولدها أمر `gradle wrapper --gradle-version 8.14.1` من تثبيت Gradle موثوق.
