import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/subjects_repository.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final SubjectsRepository _repository = SubjectsRepository();
  late Future<SubjectsCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _repository.load();
  }

  void _retry() => setState(() => _catalog = _repository.load());

  void _openSubject(SubjectEntry subject) {
    if (subject.fromSupabase && subject.id != null && subject.id!.isNotEmpty) {
      final query = Uri(queryParameters: {
        'subjectId': subject.id!,
        'subjectName': subject.name,
      }).query;
      context.push('/database-units?$query');
      return;
    }

    final query = Uri(queryParameters: {'subject': subject.name}).query;
    context.push('/lessons?$query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        centerTitle: true,
      ),
      body: FutureBuilder<SubjectsCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _LoadError(onRetry: _retry);
          }

          final catalog = snapshot.data!;
          if (catalog.subjects.isEmpty) {
            return _EmptySubjects(onRetry: _retry);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 2;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: _IntroCard(
                        year: catalog.schoolYear,
                        basis: catalog.curriculumBasis,
                      ),
                    ),
                  ),
                  if (catalog.notice != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SourceNotice(message: catalog.notice!),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = catalog.subjects[index];
                          return _SubjectCard(
                            index: index + 1,
                            subject: subject,
                            onTap: () => _openSubject(subject),
                          );
                        },
                        childCount: catalog.subjects.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth >= 720 ? 1.08 : .92,
                      ),
                    ),
                  ),
                ],
              );
            },
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
            'ابدأ رحلتك العلمية',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'اختر المادة التي تريد دراستها، ثم انتقل إلى الوحدات والدروس والتدريبات.',
            style: TextStyle(color: Colors.white.withOpacity(.9), height: 1.6),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: 'السنة $year'),
              const _InfoPill(label: 'الفرع العلمي'),
            ],
          ),
          if (basis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              basis,
              style: TextStyle(
                color: Colors.white.withOpacity(.76),
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
          color: Colors.white.withOpacity(.14),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
}

class _SourceNotice extends StatelessWidget {
  final String message;
  const _SourceNotice({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2D9A8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF946200)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF77530C),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SubjectCard extends StatelessWidget {
  final int index;
  final SubjectEntry subject;
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
    final details = <String>[];
    if (subject.unitCount != null) details.add('${subject.unitCount} وحدات');
    if (subject.lessonCount != null) details.add('${subject.lessonCount} درسًا');
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 31, color: const Color(0xFF1769E8)),
              ),
              const SizedBox(height: 12),
              Text(
                subject.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF102A4C),
                ),
              ),
              if (subject.description != null && subject.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subject.description!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              if (details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  details.join(' • '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 10,
                  ),
                ),
              ],
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'استعراض المادة',
                    style: TextStyle(
                      color: Color(0xFF1769E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF1769E8)),
                ],
              ),
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
              const Text('تعذر تحميل فهرس المواد.'),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}

class _EmptySubjects extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptySubjects({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.library_books_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('لا توجد مواد مضافة حاليًا.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('تحديث')),
            ],
          ),
        ),
      );
}
