import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/plan_catalog.dart';
import '../data/subscription_model.dart';
import '../data/subscription_service.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  late Future<SubscriptionModel?> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = SubscriptionService().fetchMySubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطط عالم العلوم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<SubscriptionModel?>(
          future: _subscription,
          builder: (context, snapshot) {
            final current = snapshot.data;
            final activeTier = current?.isPremium == true
                ? (current?.tier.toLowerCase() == 'gold'
                    ? SubscriptionTier.gold
                    : SubscriptionTier.silver)
                : SubscriptionTier.free;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff102b55), Color(0xff1769aa)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استثمر بوقتك، وارتقِ بمستواك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'اختر الخطة المناسبة لك. مدة الفضي 30 يومًا والذهبي 75 يومًا. السعر سيُعلن بعد اعتماده رسميًا.',
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  const Text(
                    'تعذر تحميل حالة الاشتراك؛ تحقق من الاتصال قبل اتخاذ أي إجراء.',
                  ),
                _PlanCard(
                  plan: PlanCatalog.free,
                  current: activeTier == SubscriptionTier.free,
                ),
                _PlanCard(
                  plan: PlanCatalog.silver,
                  current: activeTier == SubscriptionTier.silver,
                ),
                _PlanCard(
                  plan: PlanCatalog.gold,
                  current: activeTier == SubscriptionTier.gold,
                ),
                if (current?.isPremium == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'اشتراكك نشط حتى ${current!.expiresAt?.toLocal().toString().split(' ')[0] ?? 'موعد غير محدد'}.',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'تنبيه: لا تحوّل أي مبلغ قبل إعلان السعر ورقم الاستلام رسميًا. المدد المعتمدة: الفضي 30 يومًا والذهبي 75 يومًا. تفعيل المزايا المدفوعة يتطلب تأكيد الخادم.',
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool current;

  const _PlanCard({required this.plan, required this.current});

  @override
  Widget build(BuildContext context) {
    final isGold = plan.tier == SubscriptionTier.gold;
    final isSilver = plan.tier == SubscriptionTier.silver;
    final accent = isGold
        ? const Color(0xffc49a22)
        : isSilver
            ? const Color(0xff9299a3)
            : const Color(0xff1769aa);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isGold ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withOpacity(.65), width: isGold ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGold
                      ? Icons.workspace_premium
                      : isSilver
                          ? Icons.military_tech
                          : Icons.school,
                  color: accent,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الاشتراك ${plan.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(plan.tagline, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                if (current) const Chip(label: Text('خطتك الحالية')),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan.priceSyp == null
                  ? 'السعر يُعلن لاحقًا'
                  : plan.tier == SubscriptionTier.free
                      ? 'مجانًا'
                      : '${plan.priceSyp} ل.س',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            if (plan.tier != SubscriptionTier.free)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'المدة: ${plan.durationLabel}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const Divider(height: 24),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: accent, size: 19),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            if (plan.tier != SubscriptionTier.free)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: plan.isConfigured
                      ? () => context.push('/payment-help?tier=${plan.tier.name}')
                      : null,
                  child: Text(
                    plan.isConfigured
                        ? 'طلب الاشتراك ${plan.name}'
                        : 'بانتظار اعتماد السعر',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
