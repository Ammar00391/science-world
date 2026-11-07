import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final u = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(u?.email ?? 'غير مسجّل'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () async { await AuthService().signOut(); if (context.mounted) context.go('/'); }, child: const Text('تسجيل الخروج')),
          ],
        ),
      ),
    );
  }
}