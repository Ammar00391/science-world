import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GradeSelectionPage extends StatelessWidget {
  const GradeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الصف')),
      body: Center(
        child: Text('صفوف المتاحة ستظهر هنا'),
      ),
    );
  }
}
