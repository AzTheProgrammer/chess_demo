import 'package:flutter/material.dart';

/// Canonical design tokens for the chess app.
/// Source of truth: docs/design-system.md
abstract final class DesignTokens {
  // ── Color: App shell (dark-first) ──────────────────────────────────────
  static const Color bg = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceElevated = Color(0xFF242836);
  static const Color border = Color(0xFF2E3345);
  static const Color borderSubtle = Color(0xFF232735);

  static const Color textPrimary = Color(0xFFE8EAEF);
  static const Color textSecondary = Color(0xFF9AA3B5);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFF6C9EFF);
  static const Color accentSoft = Color(0x1F6C9EFF); // 12% alpha
  static const Color accentMuted = Color(0xFF4A7FD4);

  static const Color success = Color(0xFF5DD39E);
  static const Color warning = Color(0xFFF0B429);
  static const Color danger = Color(0xFFF07178);
  static const Color info = Color(0xFF6C9EFF);

  // ── Color: Board themes ────────────────────────────────────────────────
  static const BoardThemeTokens boardClassic = BoardThemeTokens(
    id: 'classic',
    label: 'Classic',
    lightSquare: Color(0xFFEEEED2),
    darkSquare: Color(0xFF769656),
  );

  static const BoardThemeTokens boardMidnight = BoardThemeTokens(
    id: 'midnight',
    label: 'Midnight',
    lightSquare: Color(0xFF8CA2AD),
    darkSquare: Color(0xFF4B6368),
  );

  static const BoardThemeTokens boardTournament = BoardThemeTokens(
    id: 'tournament',
    label: 'Tournament',
    lightSquare: Color(0xFFE8EDF9),
    darkSquare: Color(0xFF7FA650),
  );

  static const List<BoardThemeTokens> boardThemes = [
    boardClassic,
    boardMidnight,
    boardTournament,
  ];

  // ── Color: Board interaction overlays ──────────────────────────────────
  static const Color selectedSquare = Color(0xBBFFFF00);
  static const Color lastMoveHighlight = Color(0x66FFFF00);
  static const Color legalTargetEmpty = Color(0x66000000);
  static const Color legalTargetCapture = Color(0x73000000);
  static const Color checkHighlight = Color(0x99FF4444);
  static const Color coordinateLight = Color(0xCCFFFFFF);
  static const Color coordinateDark = Color(0xCC000000);

  // ── Spacing (4px base, Gestalt proximity) ──────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: space4, vertical: space4);
  static const EdgeInsets cardPadding = EdgeInsets.all(space4);
  static const double cardGap = space3;

  // ── Radii ──────────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusFull = 999;

  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);

  // ── Typography ─────────────────────────────────────────────────────────
  static const String fontFamilySans = 'Segoe UI';
  static const String fontFamilyMono = 'monospace';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.02,
    color: textSecondary,
  );

  static const TextStyle notationMono = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: textPrimary,
  );

  // ── Elevation & borders ────────────────────────────────────────────────
  static const double elevationNone = 0;
  static BorderSide get borderDefault =>
      const BorderSide(color: border, width: 1);

  // ── Motion (Doherty Threshold: <400ms) ─────────────────────────────────
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 250);
  static const Duration motionSlow = Duration(milliseconds: 350);

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubic;

  // ── Touch targets (WCAG 2.5.5) ─────────────────────────────────────────
  static const double minTouchTarget = 48;
  static const double iconSizeMd = 24;
  static const double iconSizeLg = 32;

  // ── Navigation bar ─────────────────────────────────────────────────────
  static const double navBarHeight = 80;
  static const double navIconSize = 24;
}

/// Board color pair for a named theme.
@immutable
class BoardThemeTokens {
  const BoardThemeTokens({
    required this.id,
    required this.label,
    required this.lightSquare,
    required this.darkSquare,
  });

  final String id;
  final String label;
  final Color lightSquare;
  final Color darkSquare;

  ({int light, int dark}) get argbValues => (
        light: lightSquare.toARGB32(),
        dark: darkSquare.toARGB32(),
      );
}
