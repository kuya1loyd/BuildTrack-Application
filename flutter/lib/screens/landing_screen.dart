import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (size.width * dpr * 1.25).round();

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          KenBurns(
            from: 1.04,
            to: 1.16,
            child: Image.asset(
              'assets/images/Landing.jpg',
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
                  Color(0xB3080F1C),
                  Color(0x33080F1C),
                  Color(0x99080F1C),
                  Color(0xF7080F1C),
                ],
                stops: [0, 0.3, 0.62, 1],
              ),
            ),
          ),
          // Soft amber glow behind the content for depth.
          const Positioned(
            bottom: -120,
            right: -80,
            child: Pulse(
              min: 0.92,
              max: 1.08,
              duration: Duration(milliseconds: 3600),
              child: SizedBox(
                width: 320,
                height: 320,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x40F97316), Color(0x00F97316)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Spacing.xxxl),
                  const Entrance(
                    style: EntranceStyle.popIn,
                    child: BrandLockup(showTagline: false, centered: true),
                  ),
                  const Spacer(),
                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: 6,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'CONSTRUCTION MANAGEMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          color: Color(0xFFFDBA74),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  const Entrance(
                    delay: Duration(milliseconds: 260),
                    child: Text(
                      'Build smarter.\nManage better.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  const Entrance(
                    delay: Duration(milliseconds: 320),
                    child: Text(
                      'Track projects, tasks, budgets and materials '
                      'from one place — on site or in the office.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xBFF8FAFC),
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.xxl),
                  Entrance(
                    delay: const Duration(milliseconds: 640),
                    child: GradientButton(
                      title: 'Get Started',
                      icon: Ionicons.arrow_forward,
                      onPressed: onGetStarted,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Entrance(
                    delay: const Duration(milliseconds: 720),
                    child: AppButton(
                      title: 'Sign In',
                      variant: AppButtonVariant.glass,
                      onPressed: onSignIn,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


