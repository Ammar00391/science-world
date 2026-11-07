import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة والتواصل')),
      body: const Center(child: Text('صفحة المساعدة ستظهر هنا')),
    );
  }
}
