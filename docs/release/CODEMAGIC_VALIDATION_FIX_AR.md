# تقرير إصلاح فشل تحقق Codemagic

**التاريخ:** 2026-11-09

## سبب الفشل والإصلاح

كان الأمر `python3 scripts/validate_project.py` المشار إليه في سجل البناء لا يجد السكربت في نسخة Codemagic. أُضيف الآن `scripts/validate_project.py` بفحوص فعلية، وأُدرج في خطوة واضحة من `codemagic.yaml`.

يتحقق السكربت من:

- قابلية قراءة ملفات JSON في المشروع.
- اكتمال بنية المنهاج: تسعة مواد، وحدات ودروس ومراحل التعلم المطلوبة.
- توافق بنك الأسئلة مع حالة المراجعة وعداد الأسئلة.
- وجود ملفات PDF المدرجة في manifest وتوافق الحجم والتوقيع البنيوي للملف.
- وجود الأصول المعلنة في `pubspec.yaml` وعدم فراغ مجلداتها.
- صحة مراجع Dart النسبية.
- إعداد `applicationId` وSDK وNDK وإصدار Android.
- منع Debug signing في Release، ومتطلبات أسرار التوقيع، ووجود جميع أهداف أوامر Codemagic.
- صلاحيات Manifest الأساسية وتعطيل cleartext traffic.

لا يطبع السكربت قيم مفاتيح Supabase أو كلمات مرور أو محتوى الملفات. الخيار `--production` يضيف حاجزًا يتطلب وجود سؤال offline معتمد؛ وهو يفشل حاليًا عمدًا لأن بنك التطبيق المضمّن فارغ حسب سياسة المحتوى واختباره الحالي.

## التوقيع والبناء

- مرجع Codemagic في `android_signing` هو `science_world_upload_keystore`.
- أبقى Gradle على متغيرات Codemagic السرية، ولا يوجد fallback إلى Debug.
- أُدرج التحقق من توقيع APK وAAB في نهاية الـWorkflow.
- لا تحتوي الـWorkflow خطوة نشر إلى Google Play.

## نتائج التنفيذ المحلي

| الفحص | النتيجة |
|---|---|
| `python3 scripts/validate_project.py` | ناجح؛ 765 فحصًا |
| `python3 -m py_compile scripts/validate_project.py` | ناجح |
| `bash -n` لسكربتات البناء والتحقق | ناجح |
| فحص أهداف سكربتات/أوامر Codemagic | جميعها موجودة |
| تحليل YAML | ناجح |
| `flutter analyze --no-fatal-infos` | ناجح؛ 52 ملاحظة معلوماتية دون أخطاء أو تحذيرات |
| `flutter test --reporter expanded` | ناجح؛ 26 اختبارًا |
| بناء Release APK | متوقف بأمان عند `verifyReleaseSigning`؛ أسرار Codemagic غير متاحة محليًا |
| بناء Release AAB | متوقف بأمان عند `verifyReleaseSigning`؛ أسرار Codemagic غير متاحة محليًا |
| تحقق توقيع مخرجات رسمية | لم يُنفذ؛ لم تُنتج APK/AAB موقعة رسميًا |
| النشر | لم يُنفذ |

توجد في مجلد البناء APK من تنفيذ سابق موقّعة بمفتاح Debug؛ ليست ناتج هذا الإصلاح ولا تُعد إصدارًا رسميًا. يلزم تشغيل الـWorkflow في Codemagic مع هوية `science_world_upload_keystore` المسجلة لإنتاج المخرجات الرسمية والتحقق من توقيعها.
