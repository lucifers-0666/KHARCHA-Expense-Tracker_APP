import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_textfield.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (_nameCtrl.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        }
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e.code);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with this email.';
      case 'wrong-password':    return 'Incorrect password. Please try again.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password':     return 'Password must be at least 6 characters.';
      case 'invalid-email':     return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please wait and try again.';
      default: return 'Authentication failed. Please try again.';
    }
  }

  void _toggleMode() {
    setState(() { _isLogin = !_isLogin; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHPad,
              vertical: AppSpacing.pageVPad,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.x3l),
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: isDark ? AppColors.mutedOlive : AppColors.charcoal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                  Text(
                    _isLogin ? 'Welcome back.' : 'Create account.',
                    style: AppTextStyles.display.copyWith(color: textPri),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isLogin
                        ? 'Sign in to continue tracking your finances.'
                        : 'Start your expense intelligence journey.',
                    style: AppTextStyles.body.copyWith(color: textMuted),
                  ),
                  const SizedBox(height: AppSpacing.x3l),

                  // Fields
                  if (!_isLogin) ...[
                    PremiumTextField(
                      label: 'Full Name',
                      hint: 'Your name',
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.base),
                  ],
                  PremiumTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  PremiumTextField(
                    label: 'Password',
                    hint: 'Min. 6 characters',
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 18,
                        color: textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) =>
                        (v?.length ?? 0) < 6 ? 'Min. 6 characters' : null,
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.base),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.x2l),
                  PremiumButton(
                    label: _isLogin ? 'Sign In' : 'Create Account',
                    onPressed: _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Don't have an account? " : 'Already have an account? ',
                        style: AppTextStyles.body.copyWith(color: textMuted),
                      ),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: AppTextStyles.body.copyWith(
                            color: textPri,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: textPri,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
