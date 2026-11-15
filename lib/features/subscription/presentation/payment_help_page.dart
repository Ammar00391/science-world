import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/support_contacts.dart';

class PaymentHelpPage extends StatelessWidget {
  final String tier;
  const PaymentHelpPage({super.key, this.tier = 'silver'});

  static const supportPhone = SupportContacts.whatsappPhone;
  static const whatsappUrl = SupportContacts.whatsappUrl;

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(whatsappUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب.')),
        );
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planName = tier == 'gold' ? 'الذهبي' : 'الفضي';
    return Scaffold(
      appBar: AppBar(title: const Text('طلب الاشتراك')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'الاشتراك $planName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'السعر ومدة الاشتراك ورقم الدفع لم تُعتمد بعد. لا تحوّل أي مبلغ قبل إعلان التفاصيل رسميًا.',
                style: TextStyle(height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'يمكنك التواصل مع الدعم للاستفسار عن موعد إتاحة الاشتراكات. لا يتم تفعيل أي اشتراك بمجرد إرسال رسالة أو إيصال؛ يجب التحقق من الدفع وإصدار كود من الإدارة.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          Text(
            'رقم الدعم: $supportPhone',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _openWhatsApp(context),
            icon: const Icon(Icons.chat),
            label: const Text('التواصل عبر واتساب'),
          ),
        ],
      ),
    );
  }
}
