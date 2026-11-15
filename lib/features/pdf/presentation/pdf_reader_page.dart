import 'package:flutter/material.dart';

class PdfReaderPage extends StatelessWidget {
  const PdfReaderPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قارئ PDF')),
      body: const Center(child: Text('محتوى الـ PDF سيظهر هنا')),
    );
  }
}
