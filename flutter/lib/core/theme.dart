import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFF97316);
  static const primaryDark = Color(0xFFEA580C);
  static const primaryPressed = Color(0xFFC2570B);
  static const primarySoft = Color(0xFFFFF1E6);

  static const dark = Color(0xFF0F172A);
  static const darkSoft = Color(0xFF1E293B);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const success = Color(0xFF17A34A);
  static const successSoft = Color(0xFFE6F6EC);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF2563EB);
  static const infoSoft = Color(0xFFDBEAFE);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFEDE9FE);

  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textOnDark = Color(0xFFF8FAFC);

  static const border = Color(0xFFE7E9EE);
  static const borderStrong = Color(0xFFD5DAE1);
  static const background = Color(0xFFF6F7F9);
  static const card = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);

  static const overlay = Color(0x8C0F172A);
}

abstract class Spacing {
  Spacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const pill = 999.0;
}

abstract class Shadows {
  Shadows._();
  static const card = BoxShadow(
    color: Color(0x0D0F172A),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -2,
  );
  static const float = BoxShadow(
    color: Color(0x1F0F172A),
    offset: Offset(0, 10),
    blurRadius: 24,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.card,
      ),
    );

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
