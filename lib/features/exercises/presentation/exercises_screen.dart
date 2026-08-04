import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/mb_card.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  int _catIndex = 0;

  static const _categories = ['Όλες', '😮‍💨 Αναπνοή', '🧘 Mindfulness', '✏️ Journal', '😴 Ύπνος'];

  static const _exercises = [
    (emoji: '🌬️', title: '4-7-8 Αναπνοή',       cat: 1, duration: '5 λεπτ.',  color: Color(0xFFE6F5F0), badge: 'Άγχος'),
    (emoji: '📦', title: 'Box Breathing',          cat: 1, duration: '5 λεπτ.',  color: Color(0xFFEBF4FF), badge: 'Άγχος'),
    (emoji: '🌟', title: '5-4-3-2-1 Grounding',   cat: 2, duration: '10 λεπτ.', color: Color(0xFFFEF9EC), badge: 'Πανικός'),
    (emoji: '🧠', title: 'Thought Record',         cat: 3, duration: '15 λεπτ.', color: Color(0xFFEDE9FE), badge: 'CBT'),
    (emoji: '🌿', title: 'Body Scan',              cat: 2, duration: '20 λεπτ.', color: Color(0xFFF0FDF4), badge: 'Ύπνος'),
    (emoji: '📓', title: 'Gratitude Journal',      cat: 3, duration: '10 λεπτ.', color: Color(0xFFFFF7ED), badge: 'Διάθεση'),
    (emoji: '🌙', title: 'Sleep Wind-down',        cat: 4, duration: '15 λεπτ.', color: Color(0xFFF5F3FF), badge: 'Ύπνος'),
    (emoji: '💪', title: 'Progressive Relaxation', cat: 2, duration: '20 λεπτ.', color: Color(0xFFECFDF5), badge: 'Stress'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ασκήσεις'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: List.generate(_categories.length, (i) {
                  final selected = _catIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _catIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.rFull),
                        border: Border.all(
                          color: selected ? AppColors.brand : AppColors.gridline,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        body: () {
          final filtered = _catIndex == 0
              ? _exercises
              : _exercises.where((e) => e.cat == _catIndex).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final ex = filtered[i];
              return _ExerciseCard(
                emoji: ex.emoji,
                title: ex.title,
                duration: ex.duration,
                bgColor: ex.color,
                badge: ex.badge,
              );
            },
          );
        }(),
      );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.emoji,
    required this.title,
    required this.duration,
    required this.bgColor,
    required this.badge,
  });

  final String emoji, title, duration, badge;
  final Color bgColor;

  @override
  Widget build(BuildContext context) => MbCard(
        onTap: () {},
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.rMd),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 40)),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(AppSpacing.rFull),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppSpacing.rFull),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
