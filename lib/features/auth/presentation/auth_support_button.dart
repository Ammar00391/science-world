
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/support_contacts.dart';

class AuthSupportButton extends StatelessWidget {
  const AuthSupportButton({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح التطبيق. تأكد من تثبيته.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('نحن هنا لمساعدتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.email_outlined)),
                title: const Text('الدعم عبر البريد'),
                subtitle: const Text(SupportContacts.email),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    SupportContacts.emailUri(subject: 'دعم تطبيق عالم العلوم'),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: const Text('الدعم عبر WhatsApp'),
                subtitle: const Text(SupportContacts.whatsappPhone),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, Uri.parse(SupportContacts.whatsappUrl));
                },
              ),
            ]),
          ),
        ),
      ),
      icon: const Icon(Icons.support_agent_rounded),
      label: const Text('الدعم'),
    ),
  );
}
