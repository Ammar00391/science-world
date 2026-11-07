import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionResultPage extends StatelessWidget {
  const SubscriptionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final success = args?['success'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة التفعيل')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'تم تفعيل الاشتراك بنجاح' : 'فشل تفعيل الاشتراك',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                success
                    ? 'الآن تقدر تستخدم جميع الميزات المميزة.'
                    : 'الكود غير صحيح أو منتهي الصلاحية أو تم استخدامه مسبقًا.',
                style: const TextStyle(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/subscription-status'),
                child: const Text('عرض حالة الاشتراك'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}