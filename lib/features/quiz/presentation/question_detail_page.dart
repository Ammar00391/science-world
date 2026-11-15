import 'package:flutter/material.dart';

class QuestionDetailPage extends StatelessWidget {
  const QuestionDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل السؤال')),
      body: const Center(child: Text('تفاصيل السؤال ستظهر هنا')),
    );
  }
}
