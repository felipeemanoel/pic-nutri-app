import 'package:flutter/material.dart';

import 'tokens.dart';

/// Cores semânticas além do [ColorScheme]: estados, IA, macronutrientes,
/// água e gráficos. Acesse com `context.pic`.
@immutable
class PicColors extends ThemeExtension<PicColors> {
  const PicColors({
    required this.textSecondary,
    required this.border,
    required this.surfaceMuted,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.ai,
    required this.aiContainer,
    required this.onAiContainer,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
    required this.chartLine,
    required this.chartFill,
    required this.chartGrid,
    required this.chartReference,
    required this.screenTint,
    required this.heroSurface,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroTrack,
    required this.heroWarning,
    required this.heroCarbs,
    required this.heroProtein,
    required this.heroFat,
  });

  final Color textSecondary;
  final Color border;
  final Color surfaceMuted;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color accent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color ai;
  final Color aiContainer;
  final Color onAiContainer;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color water;
  final Color chartLine;
  final Color chartFill;
  final Color chartGrid;
  final Color chartReference;

  /// Fundo levemente esverdeado das telas de painel (Início).
  final Color screenTint;

  /// Cartão-destaque do Início (resumo do dia) em verde sólido e o que vai
  /// sobre ele: texto, trilhas e as cores dos macros clareadas (≥ 4:1).
  final Color heroSurface;
  final Color onHero;
  final Color onHeroMuted;
  final Color heroTrack;
  final Color heroWarning;
  final Color heroCarbs;
  final Color heroProtein;
  final Color heroFat;

  static const light = PicColors(
    textSecondary: PicPalette.textSecondary,
    border: PicPalette.border,
    surfaceMuted: PicPalette.surfaceMuted,
    brandContainer: PicPalette.primaryLight,
    onBrandContainer: PicPalette.primaryDark,
    accent: PicPalette.accent,
    success: PicPalette.success,
    successContainer: Color(0xFFE3F4EA),
    warning: PicPalette.warningText,
    warningContainer: Color(0xFFFDF3E1),
    error: PicPalette.error,
    errorContainer: Color(0xFFFBE9EB),
    info: PicPalette.info,
    infoContainer: Color(0xFFE6F0FB),
    ai: PicPalette.aiPrimary,
    aiContainer: PicPalette.aiLight,
    onAiContainer: PicPalette.aiDark,
    protein: PicPalette.protein,
    carbs: PicPalette.carbs,
    fat: PicPalette.fat,
    water: PicPalette.water,
    chartLine: PicPalette.primary,
    chartFill: Color(0x1F0F6B4E),
    chartGrid: PicPalette.border,
    chartReference: PicPalette.textSecondary,
    screenTint: PicPalette.background,
    heroSurface: Color(0xFF0D5C43),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFCDDED7),
    heroTrack: Color(0x2EFFFFFF),
    heroWarning: Color(0xFFFFD27A),
    heroCarbs: Color(0xFFF2C879),
    heroProtein: Color(0xFFA9CFF2),
    heroFat: Color(0xFFF5AE9C),
  );

  static const dark = PicColors(
    textSecondary: PicPalette.darkTextSecondary,
    border: PicPalette.darkBorder,
    surfaceMuted: PicPalette.darkSurfaceElevated,
    brandContainer: PicPalette.darkPrimaryContainer,
    onBrandContainer: PicPalette.accent,
    accent: PicPalette.accent,
    success: PicPalette.darkSuccess,
    successContainer: Color(0xFF173B2E),
    warning: PicPalette.darkWarning,
    warningContainer: Color(0xFF3A2E17),
    error: PicPalette.darkError,
    errorContainer: Color(0xFF3F1F24),
    info: PicPalette.darkInfo,
    infoContainer: Color(0xFF1B2D42),
    ai: PicPalette.darkAiPrimary,
    aiContainer: PicPalette.darkAiContainer,
    onAiContainer: Color(0xFFDCD5FB),
    protein: PicPalette.darkProtein,
    carbs: PicPalette.darkCarbs,
    fat: PicPalette.darkFat,
    water: PicPalette.darkWater,
    chartLine: PicPalette.accent,
    chartFill: Color(0x266FD3A2),
    chartGrid: PicPalette.darkBorder,
    chartReference: PicPalette.darkTextSecondary,
    screenTint: Color(0xFF0D1311),
    heroSurface: Color(0xFF1C4A39),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFD0DDD7),
    heroTrack: Color(0x2EFFFFFF),
    heroWarning: PicPalette.darkWarning,
    heroCarbs: PicPalette.darkCarbs,
    heroProtein: PicPalette.darkProtein,
    heroFat: PicPalette.darkFat,
  );

  @override
  PicColors copyWith() => this;

  @override
  PicColors lerp(PicColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PicColors(
      textSecondary: c(textSecondary, other.textSecondary),
      border: c(border, other.border),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      brandContainer: c(brandContainer, other.brandContainer),
      onBrandContainer: c(onBrandContainer, other.onBrandContainer),
      accent: c(accent, other.accent),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      error: c(error, other.error),
      errorContainer: c(errorContainer, other.errorContainer),
      info: c(info, other.info),
      infoContainer: c(infoContainer, other.infoContainer),
      ai: c(ai, other.ai),
      aiContainer: c(aiContainer, other.aiContainer),
      onAiContainer: c(onAiContainer, other.onAiContainer),
      protein: c(protein, other.protein),
      carbs: c(carbs, other.carbs),
      fat: c(fat, other.fat),
      water: c(water, other.water),
      chartLine: c(chartLine, other.chartLine),
      chartFill: c(chartFill, other.chartFill),
      chartGrid: c(chartGrid, other.chartGrid),
      chartReference: c(chartReference, other.chartReference),
      screenTint: c(screenTint, other.screenTint),
      heroSurface: c(heroSurface, other.heroSurface),
      onHero: c(onHero, other.onHero),
      onHeroMuted: c(onHeroMuted, other.onHeroMuted),
      heroTrack: c(heroTrack, other.heroTrack),
      heroWarning: c(heroWarning, other.heroWarning),
      heroCarbs: c(heroCarbs, other.heroCarbs),
      heroProtein: c(heroProtein, other.heroProtein),
      heroFat: c(heroFat, other.heroFat),
    );
  }
}

extension PicThemeContext on BuildContext {
  PicColors get pic => Theme.of(this).extension<PicColors>() ?? PicColors.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
