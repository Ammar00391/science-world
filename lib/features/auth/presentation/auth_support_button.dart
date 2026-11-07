
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
                subtitle: const Text('sscienceworld2027@gmail.com'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, Uri(
                    scheme: 'mailto',
                    path: 'sscienceworld2027@gmail.com',
                    queryParameters: {'subject': 'دعم تطبيق عالم العلوم'},
                  ));
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: const Text('الدعم عبر WhatsApp'),
                subtitle: const Text('+90 5389857265'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, Uri.parse('https://wa.me/905389857265'));
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
