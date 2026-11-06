# إصلاح Library not found — خطوات سريعة

هذه النسخة تستخدم Supabase OAuth لتسجيل الدخول عبر Google، ولا تحتاج `google_sign_in` منفصلًا.

## افتح مجلد المشروع الصحيح

افتح المجلد الذي يحتوي على هذه الملفات معًا:

- `pubspec.yaml`
- `pubspec.lock`
- `lib/main.dart`
- `android/`

لا تفتح مجلد `lib` وحده، ولا تستخدم نسخة قديمة محفوظة من أرشيف سابق.

## Windows PowerShell

```powershell
flutter --version
flutter doctor -v
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## macOS / Linux

```bash
flutter --version
flutter doctor -v
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## متطلبات النسخة

- Dart SDK: `3.13.0` أو أحدث.
- Flutter: `3.47.0` أو أحدث وفق الحزم المقفلة في `pubspec.lock`.
- اتصال بالإنترنت أول مرة لتنزيل حزم Flutter.

## تفسير رسائل متشابهة

- `Target of URI doesn't exist: package:...`: نفّذ `flutter pub get` من جذر المشروع. إذا كان الاسم `google_sign_in` فلا تضف هذا الاستيراد؛ نسخة المشروع الحالية تستخدم Supabase OAuth.
- `Pub get failed`: راجع إصدار Flutter/Dart واتصال الإنترنت ورسالة مدير الحزم.
- `Library not found for -l...`: غالبًا رسالة ربط مكتبة أصلية من Xcode، وليست استيراد Dart؛ يلزم اسم المكتبة والمنصة وسطر الخطأ الكامل.
- فشل Google بعد فتح نافذة المتصفح: راجع Google Provider وRedirect URLs في Supabase؛ تنزيل الحزم وحده لا يفعّل OAuth.

لا تضع مفاتيح Supabase السرية أو مفاتيح service-role في ملفات Flutter أو APK.
