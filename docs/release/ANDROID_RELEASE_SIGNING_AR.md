# توقيع إصدار Android - عالم العلوم V23

## الفرق بين APK التجريبي والإصدار الرسمي

- `ScienceWorld_A1_preview_debug_signed.apk`: ملف تجريبي يستخدم مفتاح Android debug الافتراضي. يمكن تثبيته للاختبار، لكن لا تنشره ولا تعتمد عليه كتوقيع دائم لتحديثات التطبيق.
- الإصدار الرسمي: يحتاج Keystore ثابتًا يملكه صاحب التطبيق. يجب حفظ ملف Keystore وكلمات مروره في مكانين آمنين؛ لا تضعها داخل GitHub أو ZIP المصدر.

## أسرار CI المطلوبة للإصدار الرسمي

أضف المتغيرات التالية إلى Codemagic Environment Variables أو GitHub Actions Secrets:

- `ANDROID_KEYSTORE_BASE64`: محتوى Keystore بعد تحويله إلى Base64.
- `ANDROID_KEY_ALIAS`: اسم المفتاح داخل Keystore.
- `ANDROID_KEY_PASSWORD`: كلمة مرور المفتاح.
- `ANDROID_STORE_PASSWORD`: كلمة مرور ملف Keystore.

البرنامج النصي `scripts/prepare_release_signing.sh` يحول الملف في بيئة البناء فقط إلى `android/app/upload-keystore.jks` وينشئ `android/key.properties`. كلاهما مستثنى من ZIP المصدر وGit.

عند وجود Keystore صالح، يستخدم Gradle توقيع Release. عند عدم وجوده، لا يُسمح بالتوقيع debug إلا عند تحديد `ALLOW_DEBUG_SIGNED_RELEASE=true` صراحةً، وهو مسار preview فقط.

## حفظ المفتاح

لا تفقد Keystore أو كلمات المرور. إذا سبق نشر التطبيق على Google Play، يجب استخدام مفتاح الرفع/التوقيع المتوافق مع سجل التطبيق الحالي؛ لا تستبدل مفتاحًا موجودًا بمفتاح جديد من دون مراجعة إعدادات Play App Signing.
