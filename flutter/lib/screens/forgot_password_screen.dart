import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../data/repositories.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

/// Lets a user set a new password after confirming the email and phone number
/// saved on their account.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onDone,
  });

  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onBack();
    }
  }

  void _handleDone() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onDone();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.resetPassword(
        email: _email.text,
        phone: _phone.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AuthException
            ? e.message
            : 'Could not reset the password. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2A1A0E)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.xxl),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _done ? _success() : _form(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return Column(
      key: const ValueKey('done'),
      children: [
        const SizedBox(height: Spacing.xxxl * 2),
        const Entrance(
          style: EntranceStyle.popIn,
          child: Icon(
            Ionicons.checkmark_circle,
            size: 88,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        const Entrance(
          delay: Duration(milliseconds: 100),
          child: Text(
            'Password updated',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        const Entrance(
          delay: Duration(milliseconds: 160),
          child: Text(
            'You can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xBFF8FAFC)),
          ),
        ),
        const SizedBox(height: Spacing.xxl),
        GradientButton(title: 'Back to Sign In', onPressed: _handleDone),
      ],
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Entrance(
            style: EntranceStyle.slideInRight,
            child: IconBadge(
              icon: Icons.chevron_left,
              background: const Color(0x1FFFFFFF),
              tone: Colors.white,
              onPressed: _handleBack,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const Entrance(
            child: Text(
              'Reset password',
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
              'Confirm the email and phone number saved on your account, '
              'then choose a new password.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
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
              ),
              child: Column(
                children: [
                  AppField(
                    label: 'Email',
                    hint: 'you@company.com',
                    controller: _email,
                    glass: true,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Ionicons.mail_outline,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: Spacing.lg),
                  AppField(
                    label: 'Phone number on your account',
                    hint: '+20 100 123 4567',
                    controller: _phone,
                    glass: true,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Ionicons.call_outline,
                    validator: (v) =>
                        (v == null || v.replaceAll(RegExp(r'\D'), '').length < 6)
                        ? 'Enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: Spacing.lg),
                  AppField(
                    label: 'New password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    glass: true,
                    obscureText: _obscure,
                    prefixIcon: Ionicons.lock_closed_outline,
                    validator: (v) => (v == null || v.length < 8)
                        ? 'At least 8 characters'
                        : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Ionicons.eye_outline
                            : Ionicons.eye_off_outline,
                        size: 18,
                        color: const Color(0xBFFFFFFF),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  AppField(
                    label: 'Confirm new password',
                    hint: 'Repeat the password',
                    controller: _confirm,
                    glass: true,
                    obscureText: _obscure,
                    prefixIcon: Ionicons.lock_closed_outline,
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.lg),
                  GradientButton(
                    title: 'Reset Password',
                    loading: _busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: Spacing.md),
                  Center(
                    child: TextButton.icon(
                      onPressed: _busy ? null : _handleBack,
                      icon: const Icon(
                        Ionicons.arrow_back,
                        size: 14,
                        color: Color(0xFFFDBA74),
                      ),
                      label: const Text(
                        'Back to Sign In',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFDBA74),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
