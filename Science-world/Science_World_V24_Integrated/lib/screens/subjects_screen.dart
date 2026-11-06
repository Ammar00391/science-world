import 'package:flutter/material.dart';

import '../features/subjects/presentation/subjects_page.dart';

/// Backward-compatible screen name retained for older navigation code.
/// The actual implementation lives in the feature-first subjects module.
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SubjectsPage();
}
