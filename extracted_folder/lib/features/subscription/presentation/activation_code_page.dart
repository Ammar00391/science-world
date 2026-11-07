import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/subscription_service.dart';

class ActivationCodePage extends StatefulWidget {
  const ActivationCodePage({super.key});

  @override
  State<ActivationCodePage> createState() => _ActivationCodePageState();
}

class _ActivationCodePageState extends State<ActivationCodePage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _attempts = 0;
  static const maxAttempts = 3;

  Future<void> _activate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'الرجاء إدخال الكود');
      return;
    }
    if (_attempts >= maxAttempts) {
      setState(() => _error = 'لقد تجاوزت عدد المحاولات المسموح');
      return;
    }
    setState(() => _loading = true);
    final success = await SubscriptionService().activateCode(code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      context.go('/subscription-result', extra: {'success': true});
    } else {
      setState(() {
        _attempts++;
        _error = 'كود غير صحيح أو منتهي الصلاحية';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل الاشتراك')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('أدخل كود التفعيل'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(border: UnderlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _activate,
                child: _loading ? const CircularProgressIndicator() : const Text('تفعيل'),
              ),
            ),
            const SizedBox(height: 8),
            Text('ال المحاولات المتبقية: ${maxAttempts - _attempts}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}