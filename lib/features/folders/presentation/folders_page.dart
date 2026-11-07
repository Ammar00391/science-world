import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجلدات')),
      body: const Center(child: Text('قائمة المجلدات ستظهر هنا')),
    );
  }
}
