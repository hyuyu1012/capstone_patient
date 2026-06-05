import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// App-wide [ThemeData]. The design is card-on-grey with no Material elevation,
/// so most surfaces opt out of shadows and rely on 1px borders instead.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppType.family,
      scaffoldBackgroundColor: AppColors.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.labelNormal,
        displayColor: AppColors.labelStrong,
        fontFamily: AppType.family,
      ),
    );
  }
}
