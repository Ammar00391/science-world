import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B55),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(AppConstants.appNameAr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(AppConstants.appNameEn,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}