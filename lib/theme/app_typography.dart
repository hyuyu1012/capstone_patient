import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type tokens from `colors_and_type.css` + the inline styles the prototype
/// uses. Two things to know about the port:
///
/// 1. CSS `letter-spacing` is in `em` (relative to font size); Flutter's
///    [TextStyle.letterSpacing] is in logical pixels. Use [ls] to convert.
/// 2. The handoff's `--font-display` (Wanted Sans Variable) is a CDN-only
///    variable font that is not bundled, so display text falls back to
///    Pretendard Bold. Swap [displayFamily] once the font is added to assets.
abstract final class AppType {
  static const String family = 'Pretendard';
  static const String displayFamily = 'Pretendard';

  /// em → logical pixels for a given font size.
  static double ls(double em, double fontSize) => em * fontSize;

  // ── Page header (shared.jsx PageHeader) ────────────────────────
  static const TextStyle pageTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.784, // -0.028em * 28
    height: 1.15,
    color: AppColors.labelStrong,
  );
  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.027, // -0.002em
    color: AppColors.labelNeutral,
  );

  // ── Section label (small uppercase caps) ───────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.15, // 0.1em
    color: AppColors.labelNeutral,
  );

  // ── List rows (home schedule + records day rows) ───────────────
  static const TextStyle rowTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.0675, // -0.005em
    color: AppColors.labelStrong,
  );
  static const TextStyle rowSub = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.labelNeutral,
  );
  static const TextStyle rowStatus = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.22, // 0.02em
    color: AppColors.labelAlternative,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Settings ───────────────────────────────────────────────────
  static const TextStyle settingsRowLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.07, // -0.005em
    color: AppColors.labelStrong,
  );
  static const TextStyle settingsRowSub = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.023, // -0.002em
    color: AppColors.labelNeutral,
  );
}

/// Tabular-figure helper — applied to any numeric label so digits stay aligned.
extension TabularNums on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
