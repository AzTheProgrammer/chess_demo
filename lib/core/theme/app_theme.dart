import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.accent,
      brightness: Brightness.dark,
      surface: DesignTokens.surface,
    ).copyWith(
      primary: DesignTokens.accent,
      onPrimary: DesignTokens.textOnAccent,
      onSurface: DesignTokens.textPrimary,
      outline: DesignTokens.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DesignTokens.bg,
      textTheme: const TextTheme(
        displayLarge: DesignTokens.displayLarge,
        headlineMedium: DesignTokens.headlineMedium,
        titleMedium: DesignTokens.titleMedium,
        bodyLarge: DesignTokens.bodyLarge,
        bodyMedium: DesignTokens.bodyMedium,
        bodySmall: DesignTokens.bodySmall,
        labelLarge: DesignTokens.labelLarge,
        labelSmall: DesignTokens.labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.surface,
        foregroundColor: DesignTokens.textPrimary,
        elevation: DesignTokens.elevationNone,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.surface,
        elevation: DesignTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: DesignTokens.borderDefault,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DesignTokens.surface,
        indicatorColor: DesignTokens.accentSoft,
        height: DesignTokens.navBarHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.labelSmall.copyWith(color: DesignTokens.accent);
          }
          return DesignTokens.labelSmall;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: DesignTokens.accent,
              size: DesignTokens.navIconSize,
            );
          }
          return const IconThemeData(
            color: DesignTokens.textSecondary,
            size: DesignTokens.navIconSize,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.accent,
          foregroundColor: DesignTokens.textOnAccent,
          minimumSize: const Size.fromHeight(DesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.textPrimary,
          side: DesignTokens.borderDefault,
          minimumSize: const Size.fromHeight(DesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.border,
        thickness: 1,
      ),
    );
  }
}
