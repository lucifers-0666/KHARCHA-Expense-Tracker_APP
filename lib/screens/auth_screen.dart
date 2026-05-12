import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    _animCtrl.reset();
    setState(() => _isLogin = !_isLogin);
    _animCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.xxxl,
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    _isLogin ? 'Welcome\nback.' : 'Create\naccount.',
                    style: AppTextStyles.displayLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isLogin
                        ? 'Sign in to continue tracking your expenses.'
                        : 'Start your financial journey today.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Fields
                  if (!_isLogin) ...[
                    PremiumTextField(
                      label: 'Full Name',
                      hint: 'Your name',
                      controller: _nameCtrl,
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          size: 20, color: AppColors.textMuted),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  PremiumTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outline_rounded,
                        size: 20, color: AppColors.textMuted),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumTextField(
                    label: 'Password',
                    hint: 'Min 6 characters',
                    controller: _passCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 20, color: AppColors.textMuted),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    label: _isLogin ? 'Sign In' : 'Create Account',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Center(
                    child: GestureDetector(
                      onTap: _toggle,
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.body,
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                            ),
                            TextSpan(
                              text: _isLogin ? 'Sign Up' : 'Sign In',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
