import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'export_reports_screen.dart';
import 'sms_import_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'INR (₹)';

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // ── Use AppColors helper methods (single source of truth) ──────────
    final bgColor     = AppColors.bgFor(isDark);
    final cardColor   = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final textFaint   = AppColors.textFaintFor(isDark);
    // accentSoft: light mode has dedicated token; dark mode uses surfaceOffset
    final accentSoft  = isDark ? AppColors.surfaceOffsetDark : AppColors.accentSoft;

    final user = FirebaseAuth.instance.currentUser;
    final initial = user?.displayName?.isNotEmpty == true
        ? user!.displayName![0].toUpperCase()
        : user?.email?.isNotEmpty == true
            ? user!.email![0].toUpperCase()
            : 'K';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHPad,
            vertical: AppSpacing.pageVPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Title ─────────────────────────────────────────────
              Text(
                'Settings',
                style: AppTextStyles.heading.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Profile Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'KHARCHA User',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Plan badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Free',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Preferences ───────────────────────────────────────────
              _SectionLabel('Preferences', isDark),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                tiles: [
                  // Dark Mode Toggle
                  _ToggleTile(
                    icon: themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    label: 'Dark Mode',
                    value: themeProvider.isDark,
                    isDark: isDark,
                    onChanged: (val) => themeProvider.setDark(val),
                  ),
                  _CardDivider(isDark: isDark),
                  // Notifications Toggle
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  _CardDivider(isDark: isDark),
                  // Currency Selector
                  _TapTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Currency',
                    value: _selectedCurrency,
                    isDark: isDark,
                    onTap: () => _showCurrencyPicker(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Data ──────────────────────────────────────────────────
              _SectionLabel('Data', isDark),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                tiles: [
                  _TapTile(
                    icon: Icons.upload_file_rounded,
                    label: 'Export Reports',
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExportReportsScreen(),
                      ),
                    ),
                  ),
                  _CardDivider(isDark: isDark),
                  _TapTile(
                    icon: Icons.sms_outlined,
                    label: 'Import from SMS',
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SMSImportScreen(),
                      ),
                    ),
                  ),
                  _CardDivider(isDark: isDark),
                  _TapTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear All Data',
                    labelColor: AppColors.danger,
                    isDark: isDark,
                    onTap: () => _showClearDialog(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Account ───────────────────────────────────────────────
              _SectionLabel('Account', isDark),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                tiles: [
                  _TapTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    labelColor: AppColors.danger,
                    isDark: isDark,
                    onTap: () => _confirmSignOut(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.x3l),

              Center(
                child: Text(
                  'KHARCHA v1.0.0',
                  style: TextStyle(
                    color: textFaint,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Currency Picker Bottom Sheet ─────────────────────────────────────────
  void _showCurrencyPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor   = AppColors.surfaceFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.x2l),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.base),
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              Text(
                'Select Currency',
                style: AppTextStyles.headline.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.base),
              ..._currencies.map((c) => ListTile(
                    title: Text(
                      c,
                      style: TextStyle(
                        color: _selectedCurrency == c
                            ? AppColors.primary
                            : textPrimary,
                        fontWeight: _selectedCurrency == c
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: _selectedCurrency == c
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 18,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    onTap: () {
                      setState(() => _selectedCurrency = c);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  // ── Sign Out Confirmation ────────────────────────────────────────────────
  Future<void> _confirmSignOut(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardColor   = AppColors.surfaceFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        final textMuted   = AppColors.textMutedFor(isDark);
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Sign Out',
            style: AppTextStyles.title.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          // Navigate to AuthScreen and clear the entire navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to sign out. Please try again.'),
            ),
          );
        }
      }
    }
  }

  // ── Clear All Data Dialog ────────────────────────────────────────────────
  void _showClearDialog(BuildContext context, bool isDark) {
    final cardColor   = AppColors.surfaceFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Clear All Data',
          style: AppTextStyles.title.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete all your expenses and income records. This cannot be undone.',
          style: TextStyle(color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textMutedFor(isDark),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> tiles;
  const _GroupCard({required this.isDark, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderFor(isDark)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(children: tiles),
    );
  }
}

// ── Card Divider (token-aware) ────────────────────────────────────────────────
class _CardDivider extends StatelessWidget {
  final bool isDark;
  const _CardDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: AppColors.borderFor(isDark),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textMutedFor(isDark),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimaryFor(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: AppColors.textMutedFor(isDark),
        inactiveTrackColor: AppColors.borderFor(isDark),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Tap Tile ──────────────────────────────────────────────────────────────────
class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    this.value,
    this.labelColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: labelColor ?? AppColors.textMutedFor(isDark),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.textPrimaryFor(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                color: AppColors.textMutedFor(isDark),
                fontSize: 13,
              ),
            ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textFaintFor(isDark),
            size: 18,
          ),
        ],
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
