# إعداد توقيع Android الرسمي — Science World

## الحالة الحالية

إعداد Gradle لا يستخدم توقيع Debug لنسخ Release. يتطلب بناء Release جميع قيم التوقيع التي يوفرها Codemagic Code Signing Identities، ويفشل بوضوح عند غيابها أو عدم صلاحية ملف المفتاح. لم يُنشأ Keystore أو تُكتب كلمات مرور في المشروع.

في `codemagic.yaml` مرجع الهوية المطلوب هو `science_world_upload_keystore`. ارفع Keystore إلى Codemagic تحت **Team settings → Code signing identities → Android keystores**، واستخدم اسم المرجع نفسه. يوفر Codemagic تلقائيًا `CM_KEYSTORE_PATH` و`CM_KEYSTORE_PASSWORD` و`CM_KEY_ALIAS` و`CM_KEY_PASSWORD` أثناء البناء.

## إنشاء Keystore عند عدم وجود مفتاح سابق

إذا سبق نشر هذا التطبيق، لا تنشئ مفتاحًا جديدًا قبل التأكد من إعداد **Play App Signing** والمفتاح المطلوب للتحديثات. استخدم مفتاح الرفع الحالي إن كان موجودًا؛ مفتاح مختلف لن يوقّع تحديثًا قابلًا للتثبيت فوق النسخة المنشورة.

لإنشاء مفتاح رفع جديد (مرة واحدة) على جهاز موثوق، شغّل الأمر التالي من مجلد خارج المستودع. سيطلب `keytool` كلمات المرور تفاعليًا، لذلك لا تمررها كوسائط أو تضعها في سجل الأوامر:

```bash
umask 077
keytool -genkeypair -v \
  -keystore "$HOME/science-world-upload.jks" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias science-world-upload
```

اختر كلمات مرور قوية وفريدة واحفظها في مدير كلمات مرور. لا تنشئ المفتاح داخل مجلد المستودع. بعد الإنشاء:

1. احتفظ بنسختين احتياطيتين على الأقل من ملف `.jks` في موقعين منفصلين ومشفّرين وتحت سيطرتك، وتحقق من إمكانية استعادة إحداهما.
2. ارفع ملف Keystore إلى **Codemagic Code signing identities → Android keystores**. أدخل كلمة مرور المخزن، واسم alias `science-world-upload`، وكلمة مرور المفتاح، ومرجع الهوية `science_world_upload_keystore`.
3. لا تضع ملف المفتاح أو كلمات مروره في Git أو GitHub أو ملفات YAML أو رسائل/سجلات البناء. Codemagic لا يتيح تنزيل الملف المرفوع لاحقًا؛ لذلك احتفظ بنسخة خارجية آمنة.
4. لا تغيّر المفتاح أو alias أو كلمات المرور بين الإصدارات دون خطة استعادة وتحديث موثقة.

## الإصدار ورقم البناء

النسخة المعتمدة للمشروع هي `2.2.3+25` في `pubspec.yaml`:

- `2.2.3` هو `versionName` الظاهر للمستخدم.
- `25` هو `versionCode` الذي يجب أن يزيد عن كل نسخة سبق رفعها إلى Google Play.

قبل كل إصدار لاحق، حدّث سطر `version:` في `pubspec.yaml` إلى رقم إصدار مناسب ورقم بناء أعلى من السابق (مثل `2.2.4+26` عند ملاءمته). Flutter يمرر هذين الرقمين إلى إعدادات Android في أوامر البناء. أبقِ `applicationId` ثابتًا: `com.scienceworld.science_world`.

## بناء Codemagic والتحقق

يشغّل workflow المسمى `android-release` الاختبارات والتحليل، ثم يبني:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

يشغّل workflow `scripts/verify_release_artifacts.sh` بعد البناء، ويتحقق من توقيع APK باستخدام `apksigner verify` ومن توقيع AAB باستخدام `jarsigner -verify`. لا تُرفع الملفات كـArtifacts إلا بعد نجاح خطوة التحقق. إعداد workflow لا يحتوي خطوة نشر إلى Google Play. فشل تحقق التوقيع أو غياب الهوية يمنع اعتبار المخرجات إصدارًا رسميًا.
