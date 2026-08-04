import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class CrisisBanner extends StatelessWidget {
  const CrisisBanner({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  static const _lines = [
    (number: '10306', name: 'Γραμμή Ψυχολογικής Υποστήριξης', sub: 'ΕΨΥΠΕ — 24/7 — Δωρεάν'),
    (number: '1018',  name: 'Γραμμή SOS Παιδί',               sub: 'Νέοι 12–25 — 24/7'),
    (number: '166',   name: 'ΕΚΑΒ — Άμεση Ανάγκη',            sub: 'Εάν υπάρχει κίνδυνος ζωής'),
  ];

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},   // Prevent tap-through
              child: Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.rLg),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gridline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.statusCritical,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Γραμμές Βοήθειας',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                'Άμεση πρόσβαση — δωρεάν 24/7',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Lines
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (final line in _lines) ...[
                            _CrisisLine(
                              number: line.number,
                              name:   line.name,
                              sub:    line.sub,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Το MindBridge δεν αντικαθιστά επαγγελματική βοήθεια.\n'
                            'Αν νιώθεις σε κίνδυνο, επικοινώνησε αμέσως.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: onDismiss,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: const Text('Κλείσιμο'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CrisisLine extends StatelessWidget {
  const _CrisisLine({
    required this.number,
    required this.name,
    required this.sub,
  });

  final String number, name, sub;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _call,
        borderRadius: BorderRadius.circular(AppSpacing.rSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface0,
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            border: Border.all(color: AppColors.gridline),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.phone, color: AppColors.brand, size: 18),
            ],
          ),
        ),
      );
}
