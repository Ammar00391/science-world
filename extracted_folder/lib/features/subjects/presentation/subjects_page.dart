import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../curriculum/data/curriculum_repository.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final CurriculumRepository _repository = CurriculumRepository();
  late Future<CurriculumCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _repository.loadCatalog();
  }

  void _retry() => setState(() => _catalog = _repository.loadCatalog());

  String _routeFor(String subject) =>
      '/lessons?subject=${Uri.encodeQueryComponent(subject)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواد البكالوريا العلمي')),
      body: FutureBuilder<CurriculumCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _LoadError(onRetry: _retry);
          }

          final catalog = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _IntroCard(
                year: catalog.schoolYear,
                basis: catalog.curriculumBasis,
              ),
              const SizedBox(height: 16),
              ...catalog.subjects.asMap().entries.map((entry) {
                final index = entry.key;
                final subject = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubjectCard(
                    index: index + 1,
                    subject: subject,
                    onTap: () => context.push(_routeFor(subject.name)),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String year;
  final String basis;
  const _IntroCard({required this.year, required this.basis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF102E54), Color(0xFF1769E8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ابدأ من الدرس الذي تحتاجه',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر المادة، ثم الوحدة، ثم الدرس. ستجد طريقة المذاكرة والملخص والمثال والتدريب في مكان واحد.',
            style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: 'السنة $year'),
              _InfoPill(label: 'الفرع العلمي'),
            ],
          ),
          if (basis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              basis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
}

class _SubjectCard extends StatelessWidget {
  final int index;
  final CurriculumSubject subject;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.index,
    required this.subject,
    required this.onTap,
  });

  static const _icons = <IconData>[
    Icons.menu_book_rounded,
    Icons.biotech_rounded,
    Icons.volunteer_activism_rounded,
    Icons.functions_rounded,
    Icons.view_in_ar_rounded,
    Icons.science_rounded,
    Icons.bolt_rounded,
    Icons.language_rounded,
    Icons.translate_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final icon = _icons[(index - 1) % _icons.length];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: const Color(0xFF1769E8)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.units.length} وحدات • ${subject.lessonCount} درسًا',
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Color(0xFF718096)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 44),
              const SizedBox(height: 10),
              const Text('تعذر تحميل فهرس المواد من الجهاز.'),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}
