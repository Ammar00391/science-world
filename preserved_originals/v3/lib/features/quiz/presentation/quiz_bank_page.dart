import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizBankPage extends StatelessWidget {
  const QuizBankPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بنك الأسئلة')),
      body: const Center(child: Text('قائمة الأسئلة ستظهر هنا')),
    );
  }
}
