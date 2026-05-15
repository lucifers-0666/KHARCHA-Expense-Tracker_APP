import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
            selectedIcon: const Icon(Icons.home_rounded, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bar_chart_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
            selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppColors.accent),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
            selectedIcon: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.accent,
            ),
            label: 'Income',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.8),
            ),
            selectedIcon: const Icon(Icons.settings_rounded, color: AppColors.accent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
