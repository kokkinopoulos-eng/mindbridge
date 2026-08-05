import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

abstract final class AppTheme {
  // ── Light ─────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.light,
          surface: AppColors.surface1,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.surface0,
        fontFamily: 'MindBridge',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface1,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.gridline,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'MindBridge',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface0,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.gridline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.gridline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
            borderSide: const BorderSide(color: AppColors.statusCritical),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 4,
            ),
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(
              fontFamily: 'MindBridge',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.rSm),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brand,
            side: const BorderSide(color: AppColors.gridline, width: 1.5),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 4,
            ),
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(
              fontFamily: 'MindBridge',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.rSm),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brand,
            textStyle: const TextStyle(
              fontFamily: 'MindBridge',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.gridline,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface2,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: AppColors.textMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontFamily: 'MindBridge',
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'MindBridge',
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.brandLight,
          labelStyle: const TextStyle(
            color: AppColors.brand,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: Color(0xFFBEE3F8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rFull),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
          ),
        ),
      );

  // ── Dark ──────────────────────────────────────────────────────────────
  static ThemeData get dark => light.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark1,
          onSurface: AppColors.textDarkPrimary,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark0,
        appBarTheme: light.appBarTheme.copyWith(
          backgroundColor: AppColors.surfaceDark1,
          foregroundColor: AppColors.textDarkPrimary,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'MindBridge',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDarkPrimary,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: light.cardTheme.copyWith(
          color: AppColors.surfaceDark2,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.gridlineDark,
          thickness: 1,
          space: 0,
        ),
      );
}
