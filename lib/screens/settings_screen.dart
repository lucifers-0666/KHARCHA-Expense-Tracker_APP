import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'export_reports_screen.dart';
import 'sms_import_screen.dart';

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
    final bgColor   = isDark ? AppColors.bgDark : AppColors.bg;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted   = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textFaint   = isDark ? AppColors.textFaintDark : AppColors.textFaint;

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
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Profile Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark ? [] : [
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
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
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
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
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

              const SizedBox(height: 28),

              // ── Preferences ───────────────────────────────────────────
              _SectionLabel('Preferences', isDark),
              const SizedBox(height: 8),
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
                  const _Divider(),
                  // Notifications Toggle
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  const _Divider(),
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

              const SizedBox(height: 20),

              // ── Data ──────────────────────────────────────────────────
              _SectionLabel('Data', isDark),
              const SizedBox(height: 8),
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
                  const _Divider(),
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
                  const _Divider(),
                  _TapTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear All Data',
                    labelColor: AppColors.danger,
                    isDark: isDark,
                    onTap: () => _showClearDialog(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Account ───────────────────────────────────────────────
              _SectionLabel('Account', isDark),
              const SizedBox(height: 8),
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

              const SizedBox(height: 36),

              Center(
                child: Text(
                  'KHARCHA v1.0.0',
                  style: TextStyle(
                    color: textFaint,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
        final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
        final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
        final borderColor = isDark ? AppColors.borderDark : AppColors.border;
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.x2l),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Currency',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
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
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 18)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    onTap: () {
                      setState(() => _selectedCurrency = c);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
        final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
        final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
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
          Navigator.pushReplacementNamed(context, '/auth');
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

  void _showClearDialog(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Clear All Data',
          style: TextStyle(
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
        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
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

// ── Divider ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56);
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
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    return ListTile(
      leading: Icon(icon, color: textMuted, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: textMuted,
        inactiveTrackColor:
            isDark ? AppColors.borderDark : AppColors.border,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted   = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textFaint   = isDark ? AppColors.textFaintDark : AppColors.textFaint;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: labelColor ?? textMuted,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? textPrimary,
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
              style: TextStyle(color: textMuted, fontSize: 13),
            ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: textFaint,
            size: 18,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
