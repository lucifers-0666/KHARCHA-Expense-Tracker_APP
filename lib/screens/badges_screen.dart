import 'package:flutter/material.dart';
import '../models/badge.dart' as kbadge;
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final service = FirestoreServices();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Badges & Achievements',
            style: AppTextStyles.heading
                .copyWith(color: textPrimary, fontSize: 18)),
      ),
      body: StreamBuilder<List<kbadge.Badge>>(
        stream: service.getBadges(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2));
          }
          final badges = snap.data ?? [];
          if (badges.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.emoji_events_outlined,
              title: 'No badges yet',
              subtitle: 'Keep tracking expenses to earn your first badge!',
              buttonLabel: 'Go to Dashboard',
              onButton: () => Navigator.pop(context),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: badges.length,
            itemBuilder: (_, i) =>
                _BadgeCard(badge: badges[i], isDark: isDark),
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final kbadge.Badge badge;
  final bool isDark;

  const _BadgeCard({required this.badge, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final earned = badge.earnedAt != null;
    final color = earned ? AppColors.gold : AppColors.textFaintFor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: earned
                ? AppColors.gold.withValues(alpha: 0.40)
                : border,
            width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_outlined, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            earned ? 'Earned!' : badge.description,
            style: TextStyle(
                color: earned ? AppColors.gold : textMuted,
                fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
