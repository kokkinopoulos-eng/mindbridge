import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../features/profile/data/profile_notifier.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined,       activeIcon: Icons.home,           label: 'Αρχική'),
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,    label: 'Συνεδρία'),
    (icon: Icons.timer_outlined,      activeIcon: Icons.timer,          label: 'Ασκήσεις'),
    (icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart,      label: 'Πρόοδος'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider).valueOrNull;
    final hasProfile = profile?.isCompleted ?? false;
    final name = profile?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MindBridge', style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        )),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasProfile && name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: hasProfile
                        ? AppColors.brand
                        : AppColors.gridline,
                    child: Text(
                      hasProfile && name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasProfile ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: shell,
      bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(
            i,
            initialLocation: i == shell.currentIndex,
          ),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.brandLight,
          elevation: 0,
          surfaceTintColor: Colors.white,
          shadowColor: AppColors.gridline,
          destinations: _tabs.map((t) => NavigationDestination(
                icon:          Icon(t.icon,       color: AppColors.textMuted),
                selectedIcon:  Icon(t.activeIcon, color: AppColors.brand),
                label:         t.label,
              )).toList(),
        ),
      );
  }
}
