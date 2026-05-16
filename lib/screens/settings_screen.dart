import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_services.dart';
import 'export_reports_screen.dart';
import 'sms_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = FirestoreServices();
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedCurrency = 'INR';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final textFaint = AppColors.textFaintFor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHPad,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Settings',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Preferences ───────────────────────────────────────────
              _SectionLabel('Preferences', isDark),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                tiles: [
                  _SwitchTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    isDark: isDark,
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  _CardDivider(isDark: isDark),
                  _SwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    isDark: isDark,
                    value: isDark,
                    onChanged: (v) {
                      context.read<ThemeProvider>().setDark(v);
                    },
                  ),
                  _CardDivider(isDark: isDark),
                  _TapTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Currency',
                    trailing: Text(
                      _selectedCurrency,
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    isDark: isDark,
                    onTap: () => _showCurrencyPicker(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Security ──────────────────────────────────────────────
              _SectionLabel('Security', isDark),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                tiles: [
                  _SwitchTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Biometric Lock',
                    isDark: isDark,
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
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
                    icon: Icons.download_outlined,
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
                        builder: (_) => const SmsImportScreen(),
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

  // ── Currency Picker ───────────────────────────────────────────────────────
  void _showCurrencyPicker(BuildContext context, bool isDark) {
    final currencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'AED'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = AppColors.surfaceFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderFor(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Currency',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...currencies.map((c) => ListTile(
                    title: Text(c, style: TextStyle(color: textPrimary)),
                    trailing: _selectedCurrency == c
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedCurrency = c);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // ── Sign Out Confirmation ─────────────────────────────────────────────────
  Future<void> _confirmSignOut(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardColor = AppColors.surfaceFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        final textMuted = AppColors.textMutedFor(isDark);
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: textMuted, fontSize: 14),
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
          // Clear entire navigation stack — back button will not return to app
          Navigator.pushNamedAndRemoveUntil(context, '/auth', (r) => false);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to sign out. Please try again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  // ── Clear All Data ────────────────────────────────────────────────────────
  Future<void> _showClearDialog(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardColor = AppColors.surfaceFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        final textMuted = AppColors.textMutedFor(isDark);
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            'Clear All Data',
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This will permanently delete all your expenses, budgets, and income records. This cannot be undone.',
            style: TextStyle(color: textMuted, fontSize: 14),
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
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await _service.clearAllData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully.'),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to clear data. Please try again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

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
      ),
      child: Column(children: tiles),
    );
  }
}

class _CardDivider extends StatelessWidget {
  final bool isDark;
  const _CardDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderFor(isDark),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;
  const _TapTile({
    required this.icon,
    required this.label,
    this.labelColor,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = labelColor ?? AppColors.textPrimaryFor(isDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textFaintFor(isDark),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryFor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: textPrimary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
