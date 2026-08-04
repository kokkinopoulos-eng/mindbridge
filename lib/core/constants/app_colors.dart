import 'package:flutter/material.dart';

/// MindBridge color system — aligned with the validated dataviz palette.
/// All series colors pass adjacent-pair CVD ΔE ≥ 8 (OKLab ×100).
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────
  static const brand        = Color(0xFF4A7FA5);
  static const brandDark    = Color(0xFF2D5A7A);
  static const brandLight   = Color(0xFFE8F2F9);

  static const accent       = Color(0xFF7BBFA5);
  static const accentLight  = Color(0xFFE6F5F0);

  // ── Neutrals (light mode) ─────────────────────────────────────────────
  static const surface0     = Color(0xFFF5F3EF);  // page plane
  static const surface1     = Color(0xFFFCFCFB);  // card surface
  static const surface2     = Color(0xFFFFFFFF);

  static const textPrimary  = Color(0xFF1A1A18);
  static const textSecondary= Color(0xFF52514E);
  static const textMuted    = Color(0xFF898781);
  static const gridline     = Color(0xFFE1E0D9);
  static const border       = Color(0x1A0B0B0B);  // rgba(11,11,11,0.10)

  // ── Neutrals (dark mode) ──────────────────────────────────────────────
  static const surfaceDark0 = Color(0xFF0D0D0D);
  static const surfaceDark1 = Color(0xFF1A1A19);
  static const surfaceDark2 = Color(0xFF242422);

  static const textDarkPrimary   = Color(0xFFFFFFFF);
  static const textDarkSecondary = Color(0xFFC3C2B7);
  static const textDarkMuted     = Color(0xFF898781);
  static const gridlineDark      = Color(0xFF2C2C2A);

  // ── Dataviz categorical (validated — adjacent-pair safe) ──────────────
  static const series1 = Color(0xFF2A78D6);  // blue
  static const series2 = Color(0xFFEB6834);  // orange
  static const series3 = Color(0xFF1BAF7A);  // aqua
  static const series4 = Color(0xFFEDA100);  // yellow
  static const series5 = Color(0xFFE87BA4);  // magenta

  // Dark mode series (same hues, stepped for dark surface)
  static const series1Dark = Color(0xFF3987E5);
  static const series2Dark = Color(0xFFD95926);
  static const series3Dark = Color(0xFF199E70);
  static const series4Dark = Color(0xFFC98500);
  static const series5Dark = Color(0xFFD55181);

  // ── Status (fixed, never themed) ─────────────────────────────────────
  static const statusGood     = Color(0xFF0CA30C);
  static const statusWarning  = Color(0xFFFAB219);
  static const statusSerious  = Color(0xFFEC835A);
  static const statusCritical = Color(0xFFD03B3B);

  // ── Sequential blue ramp (mood chart) ────────────────────────────────
  static const seqBlue100 = Color(0xFFCDE2FB);
  static const seqBlue300 = Color(0xFF6DA7EC);
  static const seqBlue450 = Color(0xFF2A78D6);
  static const seqBlue600 = Color(0xFF184F95);

  // ── Semantic shortcuts ────────────────────────────────────────────────
  static const error   = statusCritical;
  static const success = statusGood;
  static const warning = statusWarning;

  // Gradient helpers
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandDark],
  );

  static const LinearGradient onboardingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandLight, accentLight],
  );

  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F2F9), Color(0xFFE6F5F0)],
  );
}
