import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_service.dart';
import '../../subscription/data/subscription_model.dart';
import '../../subscription/data/subscription_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  final _subscriptions = SubscriptionService();
  final _name = TextEditingController();
  bool _loading = true, _saving = false, _editing = false;
  String _grade = '', _branch = '', _studentNumber = '', _avatarUrl = '';
  String? _message;
  SubscriptionModel? _subscription;
  Timer? _subscriptionTicker;
  DateTime _clockNow = DateTime.now();

  SupabaseClient? get _client => SupabaseConfig.isInitialized ? Supabase.instance.client : null;

  @override
  void initState() { super.initState(); _load(); _subscriptionTicker = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() => _clockNow = DateTime.now()); }); }

  @override
  void dispose() { _subscriptionTicker?.cancel(); _name.dispose(); super.dispose(); }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null || _client == null) { if (mounted) setState(() => _loading = false); return; }
    _name.text = (user.userMetadata?['full_name'] ?? '').toString();
    try {
      final row = await _client!.from('profiles').select().eq('id', user.id).maybeSingle();
      if (row != null) {
        _name.text = (row['display_name'] ?? _name.text).toString();
        _grade = (row['grade'] ?? '').toString();
        _branch = (row['branch'] ?? '').toString();
        _studentNumber = (row['student_number'] ?? '').toString();
        _avatarUrl = (row['avatar_url'] ?? '').toString();
      }
      _subscription = await _subscriptions.fetchMySubscription();
    } catch (_) {
      _message = 'تعذر تحميل بعض بيانات الملف الشخصي. تحقق من إعداد تحديث قاعدة البيانات.';
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    final name = _name.text.trim();
    if (user == null || _client == null) return;
    if (name.length < 2) { setState(() => _message = 'الاسم يجب أن يتكون من حرفين على الأقل.'); return; }
    setState(() { _saving = true; _message = null; });
    try {
      await _auth.updateDisplayName(name);
      await _client!.from('profiles').upsert({
        'id': user.id, 'display_name': name,
        'grade': _grade.isEmpty ? null : _grade,
        'branch': _branch.isEmpty ? null : _branch,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) setState(() { _editing = false; _message = 'تم حفظ بياناتك بنجاح.'; });
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر حفظ البيانات. تأكد من تطبيق تحديث قاعدة البيانات ثم حاول مجددًا.');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _support() async {
    const phone = '905389567265';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent('مرحبًا، أحتاج مساعدة في تطبيق عالم العلوم.')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      setState(() => _message = 'تعذر فتح واتساب.');
    }
  }

  String _date(DateTime? value) => value == null ? 'غير محدد' : '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = Theme.of(context);
    final name = _name.text.trim().isEmpty ? 'طالب عالم العلوم' : _name.text.trim();
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
          borderRadius: BorderRadius.circular(24)), child: Column(children: [
          CircleAvatar(radius: 43, backgroundColor: Colors.white24,
            backgroundImage: _avatarUrl.startsWith('https://') ? NetworkImage(_avatarUrl) : null,
            child: _avatarUrl.startsWith('https://') ? null : const Icon(Icons.person_rounded, color: Colors.white, size: 48)),
          const SizedBox(height: 12), Text(name, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), Text(user?.email ?? 'غير مسجل الدخول', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12), _pill(user?.emailConfirmedAt != null ? 'البريد الإلكتروني مؤكّد' : 'بانتظار تأكيد البريد'),
        ])),
        const SizedBox(height: 18),
        _sectionTitle('بيانات الطالب'),
        _card(Column(children: [
          if (_editing) TextField(controller: _name, maxLength: 60, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)))
          else _row(Icons.person_outline, 'الاسم', name),
          _row(Icons.email_outlined, 'البريد الإلكتروني', user?.email ?? 'غير متاح'),
          _row(Icons.verified_user_outlined, 'حالة البريد', user?.emailConfirmedAt != null ? 'مؤكّد' : 'غير مؤكّد'),
          _row(Icons.badge_outlined, 'رقم الطالب', _studentNumber.isEmpty ? 'غير متوفر' : _studentNumber),
          if (_editing) ...[
            DropdownButtonFormField<String>(value: _grade.isEmpty ? null : _grade, decoration: const InputDecoration(labelText: 'الصف الدراسي'), items: const ['التاسع','العاشر','الحادي عشر','الثاني عشر / البكالوريا'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _grade = v ?? '')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: _branch.isEmpty ? null : _branch, decoration: const InputDecoration(labelText: 'الفرع الدراسي'), items: const ['علمي','أدبي','غير محدد'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _branch = v == 'غير محدد' ? '' : (v ?? ''))),
          ] else ...[
            _row(Icons.school_outlined, 'الصف', _grade.isEmpty ? 'لم يتم تحديده' : _grade),
            _row(Icons.menu_book_outlined, 'الفرع', _branch.isEmpty ? 'لم يتم تحديده' : _branch),
          ],
          _row(Icons.calendar_today_outlined, 'تاريخ إنشاء الحساب', _date(DateTime.tryParse(user?.createdAt ?? ''))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _saving ? null : () { if (_editing) { _save(); } else { setState(() => _editing = true); } }, icon: _saving ? const SizedBox(width: 16,height: 16,child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_editing ? Icons.save_outlined : Icons.edit_outlined), label: Text(_editing ? 'حفظ التعديلات' : 'تعديل البيانات'))),
        ])),
        const SizedBox(height: 18), _sectionTitle('اشتراكي'),
        _card(_subscription == null
          ? const ListTile(leading: Icon(Icons.workspace_premium_outlined), title: Text('لا يوجد اشتراك مسجل'), subtitle: Text('يمكنك استعراض الخطط المتاحة.'))
          : Column(children: [
              _row(Icons.workspace_premium_outlined, 'الحالة', _subscription!.isPremium ? 'اشتراك فعّال' : (_subscription!.isNotStarted ? 'لم يبدأ بعد' : (_subscription!.isExpired ? 'منتهي' : _subscription!.status))),
              _row(Icons.event_available_outlined, 'تاريخ البداية', _date(_subscription!.startsAt)),
              _row(Icons.event_busy_outlined, 'تاريخ الانتهاء', _date(_subscription!.expiresAt)),
              if (_subscription!.expiresAt != null) ...[
                const SizedBox(height: 12),
                _subscriptionCountdownCard(_subscription!),
              ],
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => context.push('/subscription'),
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('عرض الخطط وتجديد الاشتراك'),
              )),
            ])),
        const SizedBox(height: 18), _sectionTitle('مساحتك الدراسية'),
        _card(Column(children: [
          _action(Icons.insights_outlined, 'التقدم الدراسي', 'راجع تقدمك ونتائجك المسجلة', () => context.push('/progress')),
          const Divider(height: 1),
          _action(Icons.quiz_outlined, 'سجل الاختبارات', 'الوصول إلى الاختبارات والنتائج المتاحة', () => context.push('/test')),
          const Divider(height: 1),
          _action(Icons.menu_book_outlined, 'المكتبة والكتب', 'تابع كتبك ومحتواك الدراسي', () => context.push('/library')),
          const Divider(height: 1),
          _action(Icons.bookmark_outline, 'المفضلة', 'المحتوى الذي حفظته', () => context.push('/favorites')),
        ])),
        const SizedBox(height: 18), _sectionTitle('الأمان والدعم'),
        _card(Column(children: [
          _action(Icons.lock_outline, 'تغيير كلمة المرور', 'استخدم خيار استعادة كلمة المرور', () => context.push('/reset')),
          const Divider(height: 1),
          _action(Icons.support_agent, 'التواصل مع الدعم', 'مساعدة تطبيق عالم العلوم', _support),
          const Divider(height: 1),
          _action(Icons.copy_outlined, 'نسخ رقم الدعم', '+90 538 956 7265', () async { await Clipboard.setData(const ClipboardData(text: '+90 538 956 7265')); if (mounted) setState(() => _message = 'تم نسخ رقم الدعم.'); }),
        ])),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.primary))),
        const SizedBox(height: 16),
        OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error, padding: const EdgeInsets.all(14)), onPressed: () async { try { await _auth.signOut(); if (context.mounted) context.go('/'); } catch (_) { if (mounted) setState(() => _message = 'تعذر تسجيل الخروج. حاول مجددًا.'); } }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
        const SizedBox(height: 18), const Center(child: Text('Science World • عالم العلوم', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    );
  }


  Widget _subscriptionCountdownCard(SubscriptionModel subscription) {
    final expiry = subscription.expiresAt;
    final active = subscription.isPremium && expiry != null && expiry.isAfter(_clockNow);
    final notStarted = subscription.isNotStarted;
    final countdownTarget = notStarted ? subscription.startsAt : expiry;
    final remaining = countdownTarget == null ? Duration.zero : countdownTarget.difference(_clockNow);
    final days = remaining.isNegative ? 0 : remaining.inDays;
    final hours = remaining.isNegative ? 0 : remaining.inHours % 24;
    final minutes = remaining.isNegative ? 0 : remaining.inMinutes % 60;
    final gold = subscription.tier.toLowerCase() == 'gold';
    final accent = gold ? const Color(0xFFD4A017) : const Color(0xFF9AA3AD);
    final total = expiry != null && subscription.startsAt != null
        ? expiry.difference(subscription.startsAt!).inSeconds : 0;
    final elapsed = subscription.startsAt == null ? 0 : _clockNow.difference(subscription.startsAt!).inSeconds;
    final progress = notStarted || total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(.45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.workspace_premium_rounded, color: accent, size: 26),
          const SizedBox(width: 8),
          Expanded(child: Text(gold ? 'الاشتراك الذهبي 👑' : 'الاشتراك الفضي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Text(active ? 'نشط' : notStarted ? 'لم يبدأ بعد' : 'منتهي', style: TextStyle(color: active ? Colors.green : notStarted ? Colors.blue : Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        Text(notStarted ? 'الوقت المتبقي حتى بداية اشتراكك' : 'الوقت المتبقي من اشتراكك'),
        const SizedBox(height: 4),
        Text(active || notStarted ? '$days يوم و$hours ساعة و$minutes دقيقة' : 'انتهت مدة الاشتراك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: accent.withOpacity(.18), color: accent)),
        const SizedBox(height: 10),
        Text('تاريخ الانتهاء: ${_date(expiry)}', style: Theme.of(context).textTheme.bodySmall),
        if (!active && !notStarted) Padding(padding: const EdgeInsets.only(top: 8), child: Text('انتهى الوصول إلى المزايا المدفوعة؛ يمكنك عرض الخطط للتجديد.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
        if (notStarted) Padding(padding: const EdgeInsets.only(top: 8), child: Text('سيتم فتح مزايا الاشتراك تلقائيًا عند حلول تاريخ البداية.', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12))),
      ]),
    );
  }

  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)));
  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)));
  Widget _card(Widget child) => Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.3))), child: Padding(padding: const EdgeInsets.all(14), child: child));
  Widget _row(IconData icon, String title, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))), const SizedBox(width: 8), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_left), onTap: onTap);
}
