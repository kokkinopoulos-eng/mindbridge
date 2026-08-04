import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_card.dart';

class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key, this.assessmentType});
  final String? assessmentType;

  static const _types = [
    (id: 'phq9',  label: 'PHQ-9',  title: 'Κατάθλιψη', emoji: '😔', color: Color(0xFF2A78D6)),
    (id: 'gad7',  label: 'GAD-7',  title: 'Άγχος',      emoji: '😰', color: Color(0xFF6B46C1)),
    (id: 'pss10', label: 'PSS-10', title: 'Stress',      emoji: '🔥', color: Color(0xFFEB6834)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Αξιολόγηση & Πρόοδος')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            MbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ΤΕΛΕΥΤΑΙΑ ΑΞΙΟΛΟΓΗΣΗ — 28 ΙΟΥ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _ScorePill(label: 'GAD-7',  score: '8/21',  color: const Color(0xFF6B46C1)),
                      const SizedBox(width: AppSpacing.sm),
                      _ScorePill(label: 'PHQ-9',  score: '5/27',  color: AppColors.series1),
                      const SizedBox(width: AppSpacing.sm),
                      _ScorePill(label: 'PSS-10', score: '18/40', color: AppColors.series2),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'ΕΠΙΛΕΞΕ ΑΞΙΟΛΟΓΗΣΗ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final t in _types) ...[
              _AssessmentTypeTile(
                emoji: t.emoji,
                label: t.label,
                title: t.title,
                color: t.color,
                onTap: () => context.go(AppRoutes.assessmentPath(t.id)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      );
}

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key, required this.assessmentType});
  final String assessmentType;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Αποτελέσματα ${assessmentType.toUpperCase()}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 60)),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Αξιολόγηση ολοκληρώθηκε!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              MbButton(
                label: 'Επιστροφή',
                onPressed: () => context.go(AppRoutes.progress),
              ),
            ],
          ),
        ),
      );
}

// ── Supporting widgets ─────────────────────────────────────────────────────
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.score, required this.color});
  final String label, score;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.rFull),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            Text(score, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _AssessmentTypeTile extends StatelessWidget {
  const _AssessmentTypeTile({
    required this.emoji,
    required this.label,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String emoji, label, title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MbCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      );
}
