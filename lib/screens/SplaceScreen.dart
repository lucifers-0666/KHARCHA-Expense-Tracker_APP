import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    Navigator.of(context).pushReplacementNamed(
      user != null ? '/home' : '/auth',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.shadowColor,
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: isDark
                        ? AppColors.mutedOlive
                        : AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'KHARCHA',
                  style: AppTextStyles.headline.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Expense Intelligence',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(
                      isDark ? AppColors.mutedOlive : AppColors.slate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
