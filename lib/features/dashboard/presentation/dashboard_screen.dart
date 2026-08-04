import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/crisis_banner.dart';
import '../../../shared/widgets/mb_card.dart';

// ── Mock mood data (replace with Riverpod provider from API) ──────────────
final _moodData = [
  FlSpot(0, 5.2), FlSpot(1, 6.0), FlSpot(2, 5.5),
  FlSpot(3, 7.1), FlSpot(4, 6.8), FlSpot(5, 7.4),
  FlSpot(6, 8.0), FlSpot(7, 7.2), FlSpot(8, 7.5),
  FlSpot(9, 6.9), FlSpot(10, 7.8), FlSpot(11, 7.2),
  FlSpot(12, 8.1), FlSpot(13, 7.6),
];

// ── Screen ─────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showCrisis = false;
  int _selectedMood = 3; // index 0-4

  static const _moods = ['😢', '😞', '😐', '🙂', '😊'];
  static const _moodLabels = ['Άσχημα', 'Λίγο άσχημα', 'Μέτρια', 'Καλά', 'Πολύ καλά'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Greeting header ─────────────────────────────────────
              SliverToBoxAdapter(child: _GreetingHeader(
                selectedMood: _selectedMood,
                moods: _moods,
                moodLabels: _moodLabels,
                onMoodSelected: (i) => setState(() => _selectedMood = i),
                onStartSession: () => context.go(AppRoutes.chat),
              )),

              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Stats row ────────────────────────────────────
                    _StatsRow(),
                    const SizedBox(height: AppSpacing.md),

                    // ── Mood chart ───────────────────────────────────
                    MbCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ΔΙΑΘΕΣΗ — ΤΕΛΕΥΤΑΙΕΣ 2 ΕΒΔΟΜΑΔΕΣ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _MoodLineChart(data: _moodData),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Quick actions ────────────────────────────────
                    const Text(
                      'ΓΡΗΓΟΡΕΣ ΕΝΕΡΓΕΙΕΣ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickActionsGrid(
                      onCrisis: () => setState(() => _showCrisis = true),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Last assessment ──────────────────────────────
                    _LastAssessmentCard(),
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),

          if (_showCrisis)
            CrisisBanner(onDismiss: () => setState(() => _showCrisis = false)),
        ],
      ),
    );
  }
}

// ── Greeting header ────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.selectedMood,
    required this.moods,
    required this.moodLabels,
    required this.onMoodSelected,
    required this.onStartSession,
  });

  final int selectedMood;
  final List<String> moods, moodLabels;
  final ValueChanged<int> onMoodSelected;
  final VoidCallback onStartSession;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Καλημέρα';
    if (h < 17) return 'Καλό απόγευμα';
    return 'Καλό βράδυ';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const Text(
              'Γεια σου, Μαρία 👋',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Mood selector
            const Text(
              'Πώς νιώθεις τώρα;',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(moods.length, (i) {
                  final isSelected = selectedMood == i;
                  return GestureDetector(
                    onTap: () => onMoodSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.28)
                            : Colors.white.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.rFull),
                        border: Border.all(
                          color: Colors.white
                              .withOpacity(isSelected ? 0.5 : 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(moods[i],
                              style: const TextStyle(fontSize: 18)),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Text(
                              moodLabels[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // CTA
            GestureDetector(
              onTap: onStartSession,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.rSm),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ξεκίνα συνεδρία',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Μίλα με το AI τώρα — 24/7 διαθέσιμο',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Stats row ──────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: const [
          Expanded(child: _StatTile(value: '7.2', label: 'Μέση\nΔιάθεση',  delta: '+0.4', deltaUp: true)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: _StatTile(value: '12',  label: 'Ημέρες\nStreak',  delta: '🔥 Ρεκόρ', deltaUp: true)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: _StatTile(value: '8',   label: 'Συνεδρίες\nμήνα', delta: 'Αυτόν τον μήνα', deltaUp: null)),
        ],
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaUp,
  });

  final String value, label, delta;
  final bool? deltaUp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delta,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: deltaUp == null
                    ? AppColors.textMuted
                    : deltaUp!
                        ? AppColors.statusGood
                        : AppColors.statusCritical,
              ),
            ),
          ],
        ),
      );
}

// ── Mood line chart (fl_chart) ─────────────────────────────────────────────
class _MoodLineChart extends StatelessWidget {
  const _MoodLineChart({required this.data});
  final List<FlSpot> data;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 130,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 10,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.gridline,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 5,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 2,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    final labels = [
                      '22/7','','24/7','','26/7','','28/7',
                      '','30/7','','1/8','','3/8','',
                    ];
                    if (idx < labels.length && labels[idx].isNotEmpty) {
                      return Text(
                        labels[idx],
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textMuted,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  '${s.y.toStringAsFixed(1)}/10',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                color: AppColors.series1,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3.5,
                    color: AppColors.series1,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.series1.withOpacity(0.2),
                      AppColors.series1.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Quick actions ──────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onCrisis});
  final VoidCallback onCrisis;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.6,
        children: [
          _QuickCard(
            icon: Icons.flag_outlined,
            iconBg: AppColors.accentLight,
            iconColor: AppColors.series3,
            title: 'Ασκήσεις',
            subtitle: 'Αναπνοή, grounding',
            onTap: () => context.go(AppRoutes.exercises),
          ),
          _QuickCard(
            icon: Icons.assignment_outlined,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF6B46C1),
            title: 'Αξιολόγηση',
            subtitle: 'PHQ-9, GAD-7',
            onTap: () => context.go(AppRoutes.progress),
          ),
          _QuickCard(
            icon: Icons.warning_amber_outlined,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: AppColors.statusCritical,
            title: 'Κρίση;',
            subtitle: 'Γραμμές βοήθειας',
            onTap: onCrisis,
          ),
          _QuickCard(
            icon: Icons.book_outlined,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: AppColors.series2,
            title: 'Ημερολόγιο',
            subtitle: 'Καταγραφή σκέψεων',
            onTap: () {},
          ),
        ],
      );
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Last assessment teaser ─────────────────────────────────────────────────
class _LastAssessmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ΤΕΛΕΥΤΑΙΑ ΑΞΙΟΛΟΓΗΣΗ — 28 ΙΟΥ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppSpacing.rFull),
                  ),
                  child: const Text(
                    'Ήπιο άγχος',
                    style: TextStyle(
                      color: AppColors.brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (label, pct, color) in [
              ('Άγχος (GAD-7)',      0.38, AppColors.series1),
              ('Κατάθλιψη (PHQ-9)', 0.19, AppColors.series3),
              ('Stress (PSS-10)',    0.45, AppColors.series4),
            ]) ...[
              _BarRow(label: label, percent: pct, color: color),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.progress),
                child: const Text('Επανάληψη αξιολόγησης'),
              ),
            ),
          ],
        ),
      );
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.gridline,
                color: color,
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${(percent * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
}
