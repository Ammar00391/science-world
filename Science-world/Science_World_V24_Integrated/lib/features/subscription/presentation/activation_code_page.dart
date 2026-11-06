import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/subscription_service.dart';

class ActivationCodePage extends StatefulWidget {
  const ActivationCodePage({super.key});

  @override
  State<ActivationCodePage> createState() => _ActivationCodePageState();
}

class _ActivationCodePageState extends State<ActivationCodePage> {
  final _codeController = TextEditingController();
  final _subscriptionService = SubscriptionService();
  bool _loading = false;
  String? _error;

  Future<void> _activate() async {
    if (_loading) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'الرجاء إدخال كود التفعيل.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _subscriptionService.activateSubscriptionCode(code);
    if (!mounted) return;

    setState(() => _loading = false);
    if (result.success) {
      context.go(
        '/subscription-result',
        extra: {'success': true, 'message': result.message},
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفعيل اشتراك Science World')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.key_rounded,
                      size: 68,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'أدخل كود التفعيل الخاص بك للاستفادة من ميزات Science World والدروس والأسئلة المشمولة في اشتراكك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _codeController,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onSubmitted: (_) => _activate(),
                      decoration: const InputDecoration(
                        labelText: 'كود التفعيل',
                        hintText: 'أدخل الكود كما وصلك',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key_rounded),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withOpacity(.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _activate,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'تفعيل الاشتراك',
                                style: TextStyle(fontSize: 17),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/subscription-plans'),
                      child: const Text('العودة إلى خطط الاشتراك'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تتم مراجعة الكود وتفعيله من الخادم، ولا يُفعّل الاشتراك بمجرد إدخال النص محليًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
