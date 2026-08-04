import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/mb_button.dart';

// ── Onboarding data ────────────────────────────────────────────────────────
class _Concern {
  const _Concern(this.emoji, this.label, this.id);
  final String emoji, label, id;
}

const _concerns = [
  _Concern('😰', 'Άγχος και ανησυχία', 'anxiety'),
  _Concern('😔', 'Θλίψη ή κατάθλιψη', 'depression'),
  _Concern('🔥', 'Burnout / εργασιακό stress', 'burnout'),
  _Concern('😴', 'Προβλήματα ύπνου', 'sleep'),
  _Concern('👥', 'Κοινωνικό άγχος', 'social_anxiety'),
  _Concern('💔', 'Σχεσιακά θέματα', 'relationships'),
  _Concern('🪞', 'Χαμηλή αυτοεκτίμηση', 'self_esteem'),
  _Concern('😤', 'Διαχείριση θυμού', 'anger'),
];

// ── Notifier ───────────────────────────────────────────────────────────────
class _OnboardingNotifier extends ChangeNotifier {
  int step = 0;
  final selectedConcerns = <String>{};
  String aiTone = 'friendly';
  int sessionMinutes = 15;

  void toggleConcern(String id) {
    if (selectedConcerns.contains(id)) {
      selectedConcerns.remove(id);
    } else {
      selectedConcerns.add(id);
    }
    notifyListeners();
  }

  void setTone(String tone) { aiTone = tone; notifyListeners(); }
  void setDuration(int min) { sessionMinutes = min; notifyListeners(); }

  bool get canProceed {
    if (step == 0) return selectedConcerns.isNotEmpty;
    return true;
  }

  void next() { step++; notifyListeners(); }
  void prev() { if (step > 0) { step--; notifyListeners(); } }
}

final _onboardingProvider =
    ChangeNotifierProvider.autoDispose((_) => _OnboardingNotifier());

// ── Screen ─────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(_onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _StepDots(current: n.step, total: 3),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: switch (n.step) {
                  0 => _ConcernsStep(key: const ValueKey(0), notifier: n),
                  1 => _ToneStep(key: const ValueKey(1), notifier: n),
                  2 => _DurationStep(key: const ValueKey(2), notifier: n),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MbButton(
                    label: n.step < 2 ? 'Συνέχεια →' : 'Ξεκίνα το MindBridge 🚀',
                    onPressed: n.canProceed
                        ? () {
                            if (n.step < 2) {
                              n.next();
                            } else {
                              context.go(AppRoutes.home);
                            }
                          }
                        : null,
                    isFullWidth: true,
                  ),
                  if (n.step > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: n.prev,
                      child: const Text('← Πίσω'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step dots ──────────────────────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current, total;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current ? AppColors.brand : AppColors.gridline,
                borderRadius: BorderRadius.circular(AppSpacing.rFull),
              ),
            ),
          ),
        ),
      );
}

// ── Step 0: Concerns ───────────────────────────────────────────────────────
class _ConcernsStep extends ConsumerWidget {
  const _ConcernsStep({super.key, required this.notifier});
  final _OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.onboardingGradient,
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
              ),
              child: Column(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Τι σε δυσκολεύει;',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Επίλεξε ό,τι ισχύει — μπορείς να αλλάξεις αυτό αργότερα.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(_concerns.length, (i) {
              final c = _concerns[i];
              final selected = notifier.selectedConcerns.contains(c.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OptionTile(
                  emoji: c.emoji,
                  label: c.label,
                  selected: selected,
                  onTap: () => notifier.toggleConcern(c.id),
                ),
              );
            }),
          ],
        ),
      );
}

// ── Step 1: AI Tone ────────────────────────────────────────────────────────
class _ToneStep extends ConsumerWidget {
  const _ToneStep({super.key, required this.notifier});
  final _OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Πώς προτιμάς να επικοινωνεί ο AI;',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Μπορείς να το αλλάξεις ανά πάσα στιγμή.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (id, emoji, title, desc) in [
              ('friendly', '😊', 'Φιλικός', 'Ζεστός, casual, σαν φίλος'),
              ('professional', '🤝', 'Επαγγελματικός', 'Δομημένος, κλινικός τόνος'),
              ('neutral', '⚖️', 'Ουδέτερος', 'Ισορροπημένος, χωρίς έντονα χαρακτηριστικά'),
            ]) ...[
              _OptionTile(
                emoji: emoji,
                label: title,
                sublabel: desc,
                selected: notifier.aiTone == id,
                onTap: () => notifier.setTone(id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      );
}

// ── Step 2: Session Duration ───────────────────────────────────────────────
class _DurationStep extends ConsumerWidget {
  const _DurationStep({super.key, required this.notifier});
  final _OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Πόση ώρα έχεις για κάθε συνεδρία;',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Το AI θα προσαρμόζει την απάντησή του.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (min, emoji, label, desc) in [
              (5,  '⚡', '5 λεπτά', 'Γρήγορο check-in — ιδανικό για καθημερινή'),
              (15, '🎯', '15 λεπτά', 'Τυπική συνεδρία — Recommended'),
              (30, '🌊', '30 λεπτά', 'Σε βάθος εξερεύνηση'),
            ]) ...[
              Stack(
                children: [
                  _OptionTile(
                    emoji: emoji,
                    label: label,
                    sublabel: desc,
                    selected: notifier.sessionMinutes == min,
                    onTap: () => notifier.setDuration(min),
                  ),
                  if (min == 15)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(AppSpacing.rFull),
                        ),
                        child: const Text(
                          'Προτεινόμενο',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      );
}

// ── Shared OptionTile ──────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
  });

  final String emoji, label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.gridline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.brandDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (sublabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sublabel!,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.brand
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.brand : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.gridline,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
}
