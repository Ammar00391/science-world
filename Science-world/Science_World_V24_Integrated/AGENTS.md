# Science World V22 project notes
- Stack: Flutter/Dart (Android target), Supabase Auth and Postgres.
- Auth flows in `lib/features/auth` use the public/publishable Supabase client only.
- Never commit or embed Supabase secret/service-role keys in the Flutter client.
- Configure the two `scienceworld://` redirects in Supabase before testing email deep links.
- For an existing V21 database, run `supabase/migrations/20261105_auth_profile_phone.sql` once.
- Run locally: `flutter pub get`, `flutter analyze`, `flutter test`.
