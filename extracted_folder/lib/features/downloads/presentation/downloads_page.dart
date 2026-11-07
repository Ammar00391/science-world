import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنزيلات')),
      body: const Center(child: Text('قائمة التنزيلات ستظهر هنا')),
    );
  }
}
