import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  static const _navy = Color(0xFF071A35);
  static const _blue = Color(0xFF2563EB);
  static const _cyan = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          const Positioned(top: -90, right: -75, child: _GlowCircle(size: 260, color: _blue)),
          const Positioned(bottom: 65, left: -110, child: _GlowCircle(size: 280, color: Color(0xFF0E7490))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48, width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [_cyan, _blue], begin: Alignment.topRight, end: Alignment.bottomLeft),
                          boxShadow: [BoxShadow(color: _cyan.withOpacity(.22), blurRadius: 22, spreadRadius: 1)],
                        ),
                        child: const Icon(Icons.science_rounded, color: Colors.white, size: 29),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('عالم العلوم', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('SCIENCE WORLD', style: TextStyle(color: Color(0xFF9DBCE5), fontSize: 10, letterSpacing: 2.2, fontWeight: FontWeight.w700)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: const Text('2026 / 2027', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Container(
                    height: 210, width: 210,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.035), border: Border.all(color: Colors.white.withOpacity(.10), width: 1.2), boxShadow: [BoxShadow(color: _blue.withOpacity(.16), blurRadius: 65, spreadRadius: 8)]),
                    child: Stack(alignment: Alignment.center, children: [
                      Container(height: 158, width: 158, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _cyan.withOpacity(.26), width: 1.2))),
                      Container(height: 118, width: 118, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_blue.withOpacity(.9), const Color(0xFF123E76)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: _blue.withOpacity(.35), blurRadius: 30)]), child: const Icon(Icons.auto_awesome_rounded, size: 60, color: Colors.white)),
                      const Positioned(top: 24, right: 35, child: Icon(Icons.bubble_chart_rounded, color: _cyan, size: 26)),
                      const Positioned(bottom: 31, left: 27, child: Icon(Icons.functions_rounded, color: Color(0xFF93C5FD), size: 28)),
                      const Positioned(bottom: 40, right: 26, child: Icon(Icons.science_outlined, color: Colors.white70, size: 24)),
                    ]),
                  ),
                  const SizedBox(height: 36),
                  const Text('مستقبلك يبدأ\nمن هنا', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 35, height: 1.28, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                  const SizedBox(height: 14),
                  const Text('رحلتك العلمية، من الصف التاسع حتى البكالوريا،\nفي تجربة تعليمية واحدة منظّمة.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB7C9E2), fontSize: 14, height: 1.8)),
                  const SizedBox(height: 28),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _FeaturePill(icon: Icons.menu_book_rounded, label: 'دروس'),
                    SizedBox(width: 8), _FeaturePill(icon: Icons.quiz_rounded, label: 'اختبارات'),
                    SizedBox(width: 8), _FeaturePill(icon: Icons.trending_up_rounded, label: 'تقدّمك'),
                  ]),
                  const Spacer(flex: 2),
                  SizedBox(width: double.infinity, height: 58, child: DecoratedBox(
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_cyan, _blue], begin: Alignment.centerRight, end: Alignment.centerLeft), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _blue.withOpacity(.3), blurRadius: 24, offset: const Offset(0, 8))]),
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 21),
                      label: const Text('ابدأ رحلتك التعليمية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    ),
                  )),
                  const SizedBox(height: 13),
                  Text('تسجيل الدخول بالبريد الإلكتروني فقط', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(.27), color.withOpacity(.02), Colors.transparent])));
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white.withOpacity(.055), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.09))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF7DD3FC), size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))]));
}
