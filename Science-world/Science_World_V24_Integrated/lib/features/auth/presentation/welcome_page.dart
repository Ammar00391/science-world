
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final returning = GoRouterState.of(context).uri.queryParameters['returning'] == '1';
    final title = returning ? 'أهلًا بعودتك!' : 'أهلًا بك في عالم العلوم!';
    final subtitle = returning
      ? 'سعداء بمتابعتك رحلتك التعليمية من جديد.'
      : 'بدأت رحلتك العلمية معنا. لنكتشف ونتعلم خطوة بخطوة.';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFFEAF4FF), Color(0xFFF8FAFF), Colors.white]),
        ),
        child: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 116, height: 116,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF2878E8).withOpacity(.15), blurRadius: 30)]),
              child: const Icon(Icons.auto_awesome_rounded, size: 58, color: Color(0xFF2878E8))),
            const SizedBox(height: 28),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF102A4C))),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF63758B))),
            const SizedBox(height: 34),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('ابدأ الآن'),
            )),
          ]),
        ))),
      ),
    );
  }
}
