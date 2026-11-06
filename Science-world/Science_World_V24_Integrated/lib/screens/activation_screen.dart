import 'package:flutter/material.dart';

import '../features/subscription/presentation/activation_code_page.dart';

/// Compatibility entry point for older navigation code.
///
/// The actual activation flow lives in ActivationCodePage and uses the single
/// SubscriptionService implementation, so legacy callers cannot drift to a
/// different RPC signature or response parser.
class ActivationScreen extends StatelessWidget {
  const ActivationScreen({super.key});

  @override
  Widget build(BuildContext context) => const ActivationCodePage();
}
