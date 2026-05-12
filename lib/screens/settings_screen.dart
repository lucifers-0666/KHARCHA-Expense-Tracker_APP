import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../widgets/premium_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            PremiumCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accentDim,
                    child: Text(
                      (user?.email?.isNotEmpty == true)
                          ? user!.email![0].toUpperCase()
                          : 'K',
                      style: AppTextStyles.headline.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'KHARCHA User',
                          style: AppTextStyles.title,
                        ),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            _SectionLabel('Preferences'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              items: [
                _SettingsTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Currency',
                  trailing: Text('INR (₹)', style: AppTextStyles.body),
                ),
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeThumbColor: AppColors.accent,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeThumbColor: AppColors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sectionGap),
            _SectionLabel('Data'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              items: [
                _SettingsTile(
                  icon: Icons.file_download_rounded,
                  label: 'Export Reports',
                  onTap: () => Navigator.pushNamed(context, '/export'),
                ),
                _SettingsTile(
                  icon: Icons.sms_rounded,
                  label: 'Import from SMS',
                  onTap: () => Navigator.pushNamed(context, '/sms-import'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sectionGap),
            _SectionLabel('Account'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsGroup(
              items: [
                _SettingsTile(icon: Icons.shield_rounded, label: 'Security'),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  labelColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/auth');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(child: Text('KHARCHA v1.0.0', style: AppTextStyles.caption)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.label);
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(height: 1, color: AppColors.divider);
          }
          return items[i ~/ 2];
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: iconColor ?? AppColors.textMuted),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: labelColor ?? AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                )
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.tileRadius),
    );
  }
}
