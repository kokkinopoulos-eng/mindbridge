import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_card.dart';
import '../../profile/data/profile_notifier.dart';

class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key, this.assessmentType});
  final String? assessmentType;

  static const _types = [
    (id: 'phq9',  label: 'PHQ-9',  title: 'Κατάθλιψη', emoji: '😔', color: Color(0xFF2A78D6)),
    (id: 'gad7',  label: 'GAD-7',  title: 'Άγχος',      emoji: '😰', color: Color(0xFF6B46C1)),
    (id: 'pss10', label: 'PSS-10', title: 'Stress',      emoji: '🔥', color: Color(0xFFEB6834)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final profile      = profileAsync.valueOrNull;
    final keypoints    = profile?.aiKeypoints ?? [];
    final dates        = profile?.aiKeypointDates ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Πρόοδος')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [

          // ── AI Psychological Observations ────────────────────────
          if (keypoints.isNotEmpty) ...[
            _SectionLabel('ΨΥΧΟΛΟΓΙΚΕΣ ΠΑΡΑΤΗΡΗΣΕΙΣ ΑΠΟ AI'),
            const SizedBox(height: AppSpacing.sm),
            MbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology_outlined,
                            color: AppColors.brand, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Αυτό που έχει παρατηρήσει ο AI για σένα',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Show last 5 keypoints, newest first
                  ...List.generate(
                    keypoints.length > 5 ? 5 : keypoints.length,
                    (i) {
                      final idx  = keypoints.length - 1 - i;
                      final kp   = keypoints[idx];
                      final date = idx < dates.length ? _formatDate(dates[idx]) : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline dot
                            Column(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 5, right: 10),
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? AppColors.brand
                                        : AppColors.gridline,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kp,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (date.isNotEmpty)
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (keypoints.length > 5)
                    Text(
                      '+ ${keypoints.length - 5} παλιότερες παρατηρήσεις',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            _SectionLabel('ΨΥΧΟΛΟΓΙΚΕΣ ΠΑΡΑΤΗΡΗΣΕΙΣ ΑΠΟ AI'),
            const SizedBox(height: AppSpacing.sm),
            MbCard(
              child: Column(
                children: [
                  const Icon(Icons.psychology_outlined,
                      size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  const Text(
                    'Δεν υπάρχουν παρατηρήσεις ακόμα',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Κάνε μερικές συνεδρίες και ο AI θα αρχίσει να δημιουργεί ψυχολογικό προφίλ.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Assessments ──────────────────────────────────────────
          _SectionLabel('ΑΞΙΟΛΟΓΗΣΕΙΣ'),
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

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Ιαν','Φεβ','Μαρ','Απρ','Μαΐ','Ιουν','Ιουλ','Αυγ','Σεπ','Οκτ','Νοε','Δεκ'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }
}

// ── Result screen ───────────────────────────────────────────────────────────
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
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
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
