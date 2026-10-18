import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../data/repositories.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onBack,
    required this.onSignUp,
    required this.onForgot,
    required this.onSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onSignUp;
  final VoidCallback onForgot;
  final Future<void> Function({required String email, required String password})
  onSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _signInMessage(e);
      });
    }
  }

  void _openForgot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(
          onBack: () => Navigator.of(context).pop(),
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  String _signInMessage(Object error) {
    // Auth failures are the only expected errors and carry their own wording;
    // checking the type (not the string) matters because AuthException.toString()
    // returns just the message.
    if (error is AuthException) return error.message;
    final text = error.toString();
    if (text.contains('Database not configured')) {
      return 'Database not configured. Start the app with --dart-define-from-file=env.json.';
    }
    if (text.contains('bridge')) {
      return text.replaceFirst('Instance of ', '').trim();
    }
    return 'Could not sign in. Check your connection.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (size.width * dpr * 1.25).round();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          KenBurns(
    from: 1.05,
    to: 1.2,
    child: Image.asset(
      'assets/images/Signin.jpg',
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stack) =>
          const ColoredBox(color: AppColors.dark),
    ),
    ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB8090F1C),
                  Color(0x8C090F1C),
                  Color(0xF2090F1C),
                ],
                stops: [0, 0.35, 1],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xxl,
                Spacing.lg,
                Spacing.xxl,
                Spacing.xxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Entrance(
                      style: EntranceStyle.slideInRight,
                      child: IconBadge(
                        icon: Icons.chevron_left,
                        background: const Color(0x1FFFFFFF),
                        tone: Colors.white,
                        onPressed: widget.onBack,
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    const Entrance(
                      style: EntranceStyle.popIn,
                      child: BrandLockup(showTagline: false, centered: true),
                    ),
                    const SizedBox(height: Spacing.xl),
                    const Entrance(
                      child: Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    const Entrance(
                      delay: Duration(milliseconds: 70),
                      child: Text(
                        'Sign in to your account to continue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xBFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    Entrance(
                      delay: const Duration(milliseconds: 140),
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.lg),
                        decoration: BoxDecoration(
                          color: const Color(0x26FFFFFF),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 30,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                        children: [
                          AppField(
                            label: 'Email or telephone number',
                            hint: 'you@company.com or 0912 345 6789',
                            controller: _email,
                            keyboardType: TextInputType.text,
                            glass: true,
                            prefixIcon: Ionicons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your email or phone number';
                              }
                              final trimmed = v.trim();
                              if (trimmed.contains('@')) {
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(trimmed)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              }
                              final digits = trimmed.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digits.length < 7 || digits.length > 15) {
                                return 'Enter a valid phone number or email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacing.lg),
                          AppField(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _password,
                            obscureText: _obscure,
                            glass: true,
                            prefixIcon: Ionicons.lock_closed_outline,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter your password'
                                : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Ionicons.eye_outline
                                    : Ionicons.eye_off_outline,
                                size: 18,
                                color: const Color(0xBFFFFFFF),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: const ValueKey('forgot_password_btn'),
                              onPressed: () {
                                widget.onForgot();
                                _openForgot();
                              },
                              icon: const Icon(
                                Ionicons.key_outline,
                                size: 14,
                                color: Color(0xFFFDBA74),
                              ),
                              label: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFDBA74),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFDBA74),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.sm,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: Spacing.lg),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: Spacing.lg),
                          GradientButton(
                            title: 'Sign In',
                            loading: _busy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xD9F8FAFC),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSignUp,
                            child: const Text(
                              'Create one',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFDBA74),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Ionicons.alert_circle_outline,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
