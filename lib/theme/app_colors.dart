import 'package:flutter/material.dart';

/// Semantic color tokens, ported verbatim from the Wanted Design System
/// (`screens/wanted/colors_and_type.css`). Only the light-theme values that the
/// prototype actually uses are mirrored here; add dark-theme variants when the
/// 설정 → 다크 모드 toggle is wired to a real theme.
///
/// `Color.fromRGBO` is used (not `withOpacity`) so the opacity-driven label
/// tokens match the CSS rgba() values exactly.
abstract final class AppColors {
  // ── Primary brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0066FF); // --c-blue-50 / --primary-normal
  static const Color primaryStrong = Color(0xFF005EEB); // hover
  static const Color primaryHeavy = Color(0xFF0054D1); // press
  static const Color blue65 = Color(0xFF4F95FF); // profile gradient start

  // Primary at the alpha values the prototype reuses for fills/tracks.
  static const Color primary04 = Color.fromRGBO(0, 102, 255, 0.04); // completed row bg
  static const Color primary08 = Color.fromRGBO(0, 102, 255, 0.08); // sheet icon chip
  static const Color primary10 = Color.fromRGBO(0, 102, 255, 0.10); // badge bg
  static const Color primary18 = Color.fromRGBO(0, 102, 255, 0.18); // calendar lvl1 / cell shadow
  static const Color primary20 = Color.fromRGBO(0, 102, 255, 0.20); // ring progress arc
  static const Color primary32 = Color.fromRGBO(0, 102, 255, 0.32); // weekly bar (inactive)
  static const Color primary40 = Color.fromRGBO(0, 102, 255, 0.40); // calendar lvl2
  static const Color primary68 = Color.fromRGBO(0, 102, 255, 0.68); // calendar lvl3
  static const Color primary78 = Color.fromRGBO(0, 102, 255, 0.78); // "완료" time text

  // ── Status ─────────────────────────────────────────────────────
  static const Color statusCautionary = Color(0xFFFF5E00); // 누락 · overdue
  static const Color statusNegative = Color(0xFFE52222); // 로그아웃
  static const Color statusPositive = Color(0xFF00BF40);
  static const Color red60 = Color(0xFFFF6363); // 통계 누락 막대
  static const Color green40 = Color(0xFF009632); // 보호자 "활성" 칩 텍스트
  static const Color green10bg = Color.fromRGBO(0, 191, 64, 0.10); // 활성 칩 배경

  // ── Labels (text) — opacity over a cool-neutral base ───────────
  static const Color labelStrong = Color.fromRGBO(23, 23, 25, 1.0);
  static const Color labelNormal = Color.fromRGBO(46, 47, 51, 0.88);
  static const Color labelNeutral = Color.fromRGBO(55, 56, 60, 0.61);
  static const Color labelAlternative = Color.fromRGBO(55, 56, 60, 0.28);
  static const Color labelAssistive = Color.fromRGBO(55, 56, 60, 0.16);

  // ── Lines / fills ──────────────────────────────────────────────
  static const Color lineNormalNormal = Color.fromRGBO(112, 115, 124, 0.22);
  static const Color lineNormalNeutral = Color.fromRGBO(112, 115, 124, 0.16);
  static const Color lineNav = Color.fromRGBO(112, 115, 124, 0.14); // bottom nav stroke
  static const Color fillNormal = Color.fromRGBO(112, 115, 124, 0.22); // toggle off track
  static const Color fillNeutral = Color.fromRGBO(112, 115, 124, 0.08); // disabled CTA bg
  static const Color fillAlternative = Color.fromRGBO(112, 115, 124, 0.05); // tracks

  // Social-login brand colors (Login screen).
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF191600);

  // ── Surfaces ───────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color pageBackground = Color(0xFFF4F5F7); // app.jsx background
  static const Color scrim = Color.fromRGBO(23, 23, 25, 0.40); // sheet overlay

  // Patient avatar gradient (135deg #4F95FF → #0066FF).
  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue65, primary],
  );
}
