import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentHelpPage extends StatelessWidget {
  final String tier;
  final int price;
  const PaymentHelpPage({super.key, this.tier = 'silver', this.price = 500});

  static const supportPhone = '+90 538 956 7265';
  static const whatsappUrl = 'https://wa.me/905389567265';

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: show phone number
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب الاشتراك')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('الاشتراك ${tier == 'gold' ? 'الذهبي' : 'الفضي'} — $price ل.س / ${tier == 'gold' ? 'شهرين ونصف (75 يومًا)' : 'شهر واحد (30 يومًا)'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('السداد عبر قناة الدعم المتاحة حاليًا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            'لطلب الاشتراك، اتبع الخطوات التالية:\n'
            '1. تواصل مع الدعم عبر واتساب.\n'
            '2. اذكر خطة ${tier == 'gold' ? 'الذهبي' : 'الفضي'} وسعرها $price ل.س لمدة ${tier == 'gold' ? '75 يومًا' : '30 يومًا'}.\n'
            '3. بعد التأكيد يُصدر كود تفعيل.\n'
            '4. أدخل الكود في التطبيق.\n\n'
            'ملاحظة: لا يتم تفعيل الاشتراك تلقائيًا بعد إرسال الإيصال.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          const Text('رقم الدعم: +90 538 956 7265', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('الواتساب: https://wa.me/905389567265'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat),
            label: const Text('التواصل لتفعيل الاشتراك'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'مهم: لا يتم تفعيل الاشتراك تلقائيًا بعد إرسال الإيصال. '
            'يجب التأكيد يدويًا من قبل فريق الدعم.',
            style: TextStyle(color: Colors.red, height: 1.5),
          ),
        ],
      ),
    );
  }
}