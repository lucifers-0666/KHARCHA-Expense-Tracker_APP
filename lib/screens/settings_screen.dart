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
    final bgColor = AppColors.bgFor(isDark);
    final cardColor = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final textFaint = AppColors.textFaintFor(isDark);
    final accentSoft = isDark
        ? AppColors.surfaceOffsetDark
        : AppColors.accentSoft;
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHPad,
            vertical: AppSpacing.pageVPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Title ───────────────────────────────────────────────
              Text(
                'Settings',
                style: AppTextStyles.heading.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Profile Card ─────────────────────────────────────────────
              _profileCard(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                accentSoft: accentSoft,
                user: user,
                initial: initial,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Preferences ──────────────────────────────────────────────
              _SectionLabel('Preferences', textMuted),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                tiles: [
                  _ToggleTile(
                    icon: themeProvider.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    label: 'Dark Mode',
                    value: themeProvider.isDark,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onChanged: (val) => themeProvider.setDark(val),
                  ),
                  _Divider(isDark: isDark, borderColor: borderColor),
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: _notificationsEnabled,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  _Divider(isDark: isDark, borderColor: borderColor),
                  _TapTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Currency',
                    value: _selectedCurrency,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => _showCurrencyPicker(
                      context,
                      isDark,
                      textPrimary,
                      textMuted,
                      cardColor,
                      borderColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Data ─────────────────────────────────────────────────────
              _SectionLabel('Data', textMuted),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                tiles: [
                  _TapTile(
                    icon: Icons.upload_file_rounded,
                    label: 'Export Reports',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const ExportReportsScreen()),
                    ),
                  ),
                  _Divider(isDark: isDark, borderColor: borderColor),
                  _TapTile(
                    icon: Icons.sms_outlined,
                    label: 'Import from SMS',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const SmsImportScreen()),
                    ),
                  ),
                  _Divider(isDark: isDark, borderColor: borderColor),
                  _TapTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear All Data',
                    labelColor: AppColors.danger,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => _showClearDialog(
                      context,
                      isDark,
                      textPrimary,
                      textMuted,
                      cardColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Account ──────────────────────────────────────────────────
              _SectionLabel('Account', textMuted),
              const SizedBox(height: AppSpacing.sm),
              _GroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                tiles: [
                  _TapTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    labelColor: AppColors.danger,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () => _confirmSignOut(
                      context,
                      isDark,
                      textPrimary,
                      textMuted,
                      cardColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.x3l),
              Center(
                child: Text(
                  'KHARCHA v1.0.0',
                  style: TextStyle(color: textFaint, fontSize: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card builder ──────────────────────────────────────────────────
  Widget _profileCard({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required Color accentSoft,
    required User? user,
    required String initial,
  }) {
    final name = user?.displayName ?? 'KHARCHA User';
    final email = user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + email — Expanded fixes email overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Plan badge — fixed width prevents squeeze
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  // ── Currency picker ───────────────────────────────────────────────────────
  void _showCurrencyPicker(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderFor(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Currency',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._currencies.map(
              (c) => ListTile(
                dense: true,
                title: Text(
                  c,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
                trailing: _selectedCurrency == c
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedCurrency = c);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clear data dialog ─────────────────────────────────────────────────────
  void _showClearDialog(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Clear All Data',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete all your expenses and budgets. This action cannot be undone.',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign out confirm ──────────────────────────────────────────────────────
  void _confirmSignOut(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (r) => false,
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide page transition ─────────────────────────────────────────────────
  PageRouteBuilder<T> _slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, a1, a2) => page,
      transitionsBuilder: (_, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final List<Widget> tiles;

  const _GroupCard({
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.8),
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
      child: Column(children: tiles),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.accentSoft,
          ),
        ],
      ),
    );
  }
}

class _TapTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final String? value;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
    this.labelColor,
    this.value,
  });

  @override
  State<_TapTile> createState() => _TapTileState();
}

class _TapTileState extends State<_TapTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _bgAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _bgAnim = ColorTween(
      begin: Colors.transparent,
      end: AppColors.primary.withValues(alpha: 0.06),
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.labelColor ?? widget.textPrimary;
    final iconColor = widget.labelColor ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) => GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) async {
          await _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _bgAnim.value,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.value != null)
                Text(
                  widget.value!,
                  style: TextStyle(color: widget.textMuted, fontSize: 13),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  const _Divider({required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: borderColor,
      height: 0.8,
      thickness: 0.8,
      indent: 48,
      endIndent: 0,
    );
  }
}
