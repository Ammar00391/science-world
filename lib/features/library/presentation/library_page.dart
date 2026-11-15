import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة')),
      body: const Center(child: Text('قائمة الكتب ستظهر هنا')),
    );
  }
}
