import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.isInitialized ? Supabase.instance.client.auth.currentUser : null;
    final displayName = (user?.userMetadata?['full_name'] ?? '').toString().trim();
    final firstName = displayName.isEmpty ? 'أهلًا بك' : 'مرحبًا، ${displayName.split(' ').first}';
    return Scaffold(
      appBar: AppBar(
        title: const _BrandLockup(),
        actions: [
          IconButton(tooltip: 'الإشعارات', onPressed: () => context.push('/settings'), icon: const Icon(Icons.notifications_none_rounded)),
          IconButton(tooltip: 'الملف الشخصي', onPressed: () => context.push('/profile'), icon: const Icon(Icons.account_circle_outlined)),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _WelcomeHero(name: firstName, onTap: () => context.push('/profile')),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'مساحتك الدراسية', subtitle: 'كل أدواتك التعليمية في مكان واحد'),
            const SizedBox(height: 12),
            _QuickStats(onProgress: () => context.push('/progress')),
            const SizedBox(height: 22),
            const _SectionHeading(title: 'ابدأ التعلّم', subtitle: 'اختر القسم الذي تريد متابعته'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _FeatureTile(icon: Icons.menu_book_rounded, title: 'المكتبة', subtitle: 'الكتب والمراجع', color: const Color(0xFF2877E8), onTap: () => context.push('/library')),
                _FeatureTile(icon: Icons.play_lesson_rounded, title: 'الدروس', subtitle: 'شرح ومتابعة', color: const Color(0xFF159D86), onTap: () => context.push('/subjects')),
                _FeatureTile(icon: Icons.quiz_rounded, title: 'بنك الأسئلة', subtitle: 'تدرّب واختبر نفسك', color: const Color(0xFF8B5CE6), onTap: () => context.push('/quiz-bank')),
                _FeatureTile(icon: Icons.smart_toy_rounded, title: 'المساعد الذكي', subtitle: 'اسأل وتعلّم خطوة بخطوة', color: const Color(0xFFDA8A28), onTap: () => context.push('/assistant')),
                _FeatureTile(icon: Icons.event_available_rounded, title: 'الاختبارات', subtitle: 'اختبر مستواك', color: const Color(0xFFDA5D78), onTap: () => context.push('/test')),
                _FeatureTile(icon: Icons.emoji_events_rounded, title: 'الإنجازات', subtitle: 'تابع تحدياتك', color: const Color(0xFF1A9AB4), onTap: () => context.push('/gamification')),
              ],
            ),
            const SizedBox(height: 22),
            _BaccalaureateBanner(onTap: () => context.push('/world')),
            const SizedBox(height: 20),
            _FooterActions(
              onGrades: () => context.push('/grades'),
              onDownloads: () => context.push('/downloads'),
              onSettings: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 42, height: 42, padding: const EdgeInsets.all(4), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, AppColors.cyan]), borderRadius: BorderRadius.circular(14)), child: Image.asset('assets/images/science_world_logo.png', fit: BoxFit.contain)),
    const SizedBox(width: 10),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('عالم العلوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.1)), const SizedBox(height: 2), Text('SCIENCE WORLD', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFamily: 'Inter', color: AppColors.muted, letterSpacing: 1.2, fontWeight: FontWeight.w800))]),
  ]);
}

class _WelcomeHero extends StatelessWidget {
  final String name; final VoidCallback onTap;
  const _WelcomeHero({required this.name, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      image: const DecorationImage(image: AssetImage('assets/images/science_hero_background.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0x99071930), BlendMode.darken)),
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.navy, AppColors.navySoft, Color(0xFF1457A6)]),
      boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(.16), blurRadius: 24, offset: const Offset(0, 10))],
    ),
    child: Stack(children: [
      Positioned(left: -26, top: -28, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.08), width: 18)))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: onTap, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70))]),
        const Text('خطوة صغيرة كل يوم تصنع فرقًا كبيرًا.', style: TextStyle(color: Color(0xFFD5E7FF), fontSize: 13, height: 1.7)),
        const SizedBox(height: 18),
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 18), const SizedBox(width: 7),
          const Expanded(child: Text('تعلّم • تدرب • تقدّم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(30)), child: const Text('2026 / 2027', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
      ]),
    ]),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeading({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted))]);
}

class _QuickStats extends StatelessWidget {
  final VoidCallback onProgress;
  const _QuickStats({required this.onProgress});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(22), onTap: onProgress,
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)), child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.insights_rounded, color: AppColors.blue)),
      const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تقدّمك الدراسي', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('افتح تقريرك لمراجعة نشاطك المسجّل', style: TextStyle(color: AppColors.muted, fontSize: 11))])),
      const Icon(Icons.chevron_left_rounded, color: AppColors.muted),
    ])),
  );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const _FeatureTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(22),
    child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 43, height: 43, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 23)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10.5))]),
      ]),
    )),
  );
}

class _BaccalaureateBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _BaccalaureateBanner({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Container(
    padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFEAF3FF), Color(0xFFDCEBFF)]), border: Border.all(color: const Color(0xFFD2E2FA))),
    child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.school_rounded, color: AppColors.blue, size: 26)), const SizedBox(width: 13), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رحلتك نحو البكالوريا', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)), SizedBox(height: 3), Text('خطّط لمذاكرتك وتابع رحلتك التعليمية', style: TextStyle(fontSize: 11, color: AppColors.muted))])), const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.blue, size: 16)]),
  ));
}

class _FooterActions extends StatelessWidget {
  final VoidCallback onGrades, onDownloads, onSettings;
  const _FooterActions({required this.onGrades, required this.onDownloads, required this.onSettings});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _FooterButton(icon: Icons.school_outlined, label: 'الصفوف', onTap: onGrades)),
    const SizedBox(width: 9), Expanded(child: _FooterButton(icon: Icons.download_outlined, label: 'التنزيلات', onTap: onDownloads)),
    const SizedBox(width: 9), Expanded(child: _FooterButton(icon: Icons.settings_outlined, label: 'الإعدادات', onTap: onSettings)),
  ]);
}
class _FooterButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _FooterButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 17), label: Text(label, style: const TextStyle(fontSize: 11)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12), minimumSize: Size.zero));
}
