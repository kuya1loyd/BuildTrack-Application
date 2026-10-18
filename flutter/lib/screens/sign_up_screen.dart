import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../data/repositories.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onSignUp,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    String? company,
    String? phone,
  })
  onSignUp;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _accepted = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      setState(
        () => _error = 'Please accept the Terms of Service to continue.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        company: _company.text.trim(),
        phone: _phone.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendly(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    background: Colors.white,
                    onPressed: widget.onBack,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                const Entrance(
                  style: EntranceStyle.popIn,
                  child: Center(
                    child: BrandLockup(
                      showTagline: false,
                      iconSize: 44,
                      nameSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                const Entrance(
                  child: Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                const Entrance(
                  delay: Duration(milliseconds: 80),
                  child: Text(
                    'Set up your BuildTrack workspace in a minute',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Entrance(
                  delay: const Duration(milliseconds: 140),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [Shadows.card],
                    ),
                    child: _form(),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSignIn,
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          label: 'Full name',
          hint: 'Your name',
          controller: _name,
          prefixIcon: Ionicons.person_outline,
          validator: (v) =>
              (v == null || v.trim().length < 2) ? 'Enter your name' : null,
        ),
        const SizedBox(height: Spacing.lg),
        AppField(
          label: 'Email',
          hint: 'you@company.com',
          controller: _email,
          prefixIcon: Ionicons.mail_outline,
          keyboardType: TextInputType.emailAddress,
           validator: (v) {
             if (v == null || v.isEmpty) {
               return 'Enter an email';
             }
             final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
             if (!emailRegex.hasMatch(v)) {
               return 'Enter a valid email';
             }
             return null;
           },
        ),
        const SizedBox(height: Spacing.lg),
        AppField(
          label: 'Company (optional)',
          hint: 'Company name',
          controller: _company,
          prefixIcon: Ionicons.business_outline,
        ),
        const SizedBox(height: Spacing.lg),
        AppField(
          label: 'Phone number (optional)',
          hint: '+20 100 123 4567',
          controller: _phone,
          prefixIcon: Ionicons.call_outline,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: Spacing.lg),
        AppField(
          label: 'Password',
          hint: 'Create a password',
          controller: _password,
          obscureText: _obscure,
          prefixIcon: Ionicons.lock_closed_outline,
           validator: (v) {
             if (v == null || v.isEmpty) {
               return 'Enter a password';
             }
             if (v.length < 8) {
               return 'At least 8 characters';
             }
             // Check for at least one uppercase letter
             if (!v.contains(RegExp(r'[A-Z]'))) {
               return 'At least one uppercase letter';
             }
             // Check for at least one lowercase letter
             if (!v.contains(RegExp(r'[a-z]'))) {
               return 'At least one lowercase letter';
             }
             // Check for at least one digit
             if (!v.contains(RegExp(r'[0-9]'))) {
               return 'At least one digit';
             }
             // Check for at least one special character
             if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
               return 'At least one special character';
             }
             return null;
           },
          suffix: IconButton(
            icon: Icon(
              _obscure ? Ionicons.eye_outline : Ionicons.eye_off_outline,
              size: 18,
              color: AppColors.textMuted,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _accepted = !_accepted),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: _accepted ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: _accepted
                        ? AppColors.primary
                        : AppColors.borderStrong,
                  ),
                ),
                alignment: Alignment.center,
                child: _accepted
                    ? const Icon(
                        Ionicons.checkmark,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: Spacing.md),
              const Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Spacing.lg),
          _ErrorBanner(message: _error!),
        ],
        const SizedBox(height: Spacing.xl),
        GradientButton(
          title: 'Create Account',
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }

  String _friendly(Object error) {
    if (error is AuthException) return error.message;
    final text = error.toString();
    if (text.length > 200) return '${text.substring(0, 200)}…';
    return text;
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
