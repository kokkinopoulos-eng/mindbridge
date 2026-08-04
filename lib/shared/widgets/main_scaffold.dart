import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/app_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined,       activeIcon: Icons.home,           label: 'Αρχική'),
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,    label: 'Συνεδρία'),
    (icon: Icons.timer_outlined,      activeIcon: Icons.timer,          label: 'Ασκήσεις'),
    (icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart,      label: 'Πρόοδος'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
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
