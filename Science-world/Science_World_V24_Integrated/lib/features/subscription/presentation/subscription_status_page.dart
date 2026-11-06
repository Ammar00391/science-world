import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/subscription_service.dart';
import '../data/subscription_model.dart';

class SubscriptionStatusPage extends StatelessWidget {
  const SubscriptionStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حالة الاشتراك')),
      body: FutureBuilder<SubscriptionModel?>(
        future: SubscriptionService().fetchMySubscription(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sub = snapshot.data;
          if (sub == null || sub.status == 'free') {
            return Center(
              child: Column(
               mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('لا توجد اشتراكي نشط', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/subscription-plans'),
                    child: const Text('الاشتراك الآن'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(
                sub.isPremium ? Icons.check_circle : Icons.info,
                color: sub.isPremium ? Colors.green : Colors.blue,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                sub.isPremium ? 'الاشتراك نشط' : 'الاشتراك منتهي',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildRow('الحالة', sub.status),
              _buildRow('البداية', sub.startsAt?.toLocal().toString().split(' ')[0] ?? '-'),
              _buildRow('النهاية', sub.expiresAt?.toLocal().toString().split(' ')[0] ?? '-'),
              _buildRow('الأيام المتبقية', sub.daysRemaining.toString()),
              if (sub.isPremium) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/activate'),
                  child: const Text('تفعيل كود جديد'),
                ),
              ],
              if (sub.isExpired) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/payment-help'),
                  child: const Text('تجديد الاشتراك'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}