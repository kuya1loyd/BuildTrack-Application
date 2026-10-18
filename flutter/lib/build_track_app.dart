import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/db_config.dart';
import 'screens/landing_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/app_shell.dart';
import 'screens/forgot_password_screen.dart';
import 'state/app_state.dart';

class BuildTrackApp extends StatelessWidget {
  const BuildTrackApp({super.key});

  /// Widest the app is allowed to get. On a desktop browser the mobile layout
  /// (dashboard grid included) must not stretch across the whole window, so
  /// the app is pinned to a phone-like column and centered.
  static const _maxAppWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.booting) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: _frame,
        home: const _BootSplash(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuildTrack',
      theme: AppTheme.light,
      builder: _frame,
      home: _RootRouter(state: state),
    );
  }

  Widget _frame(BuildContext context, Widget? child) {
    return _AppFrame(
      maxWidth: _maxAppWidth,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _AppFrame extends StatelessWidget {
  const _AppFrame({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return ColoredBox(
          color: AppColors.dark,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter({required this.state});

  final AppState state;

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  var _route = 'landing';

  void _go(String route) => setState(() => _route = route);

  @override
  Widget build(BuildContext context) {
    if (!DbConfig.isConfigured) {
      return const _SetupNotice();
    }

    final state = widget.state;
    final hasUser = state.hasUser;

    final screen = hasUser
        ? AppShell(
            onSignOut: () async {
              await state.signOut();
              if (!mounted) return;
              _go('landing');
            },
          )
        : switch (_route) {
            'signIn' => SignInScreen(
              onBack: () => _go('landing'),
              onSignUp: () => _go('signUp'),
              onForgot: () => _go('forgot'),
              onSignIn: ({required email, required password}) =>
                  state.signIn(email: email, password: password),
            ),
            'forgot' => ForgotPasswordScreen(
              onBack: () => _go('signIn'),
              onDone: () => _go('signIn'),
            ),
            'signUp' => SignUpScreen(
              onBack: () => _go('landing'),
              onSignIn: () => _go('signIn'),
              onSignUp:
                  ({
                    required name,
                    required email,
                    required password,
                    company,
                    phone,
                  }) => state.signUp(
                    name: name,
                    email: email,
                    password: password,
                    company: company ?? '',
                    phone: phone ?? '',
                  ),
            ),
            _ => LandingScreen(
              onGetStarted: () => _go('signUp'),
              onSignIn: () => _go('signIn'),
            ),
          };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(hasUser ? 'app' : _route),
        child: screen,
      ),
    );
  }
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect BuildTrack to your database',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              const Text(
                'Create an env.json file next to pubspec.yaml with your Neon '
                'connection string, then start the app with '
                '--dart-define-from-file=env.json.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xBFF8FAFC),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0x3DFFFFFF)),
                ),
                child: const SelectableText(
                  '{"NEON_DATABASE_URL": "postgresql://user:pass@host/db?sslmode=require"}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
