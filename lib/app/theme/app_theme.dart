import 'package:flutter/material.dart';

import '../../core/design/pic_colors.dart';
import '../../core/design/tokens.dart';

/// Tema do PicNutri (Material 3) montado a partir dos tokens do Design System.
/// Telas não definem cores nem estilos próprios: usam o tema e `context.pic`.
abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData light() => _build(_lightScheme, PicColors.light);

  static ThemeData dark() => _build(_darkScheme, PicColors.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: PicPalette.primary,
    onPrimary: Colors.white,
    primaryContainer: PicPalette.primaryLight,
    onPrimaryContainer: PicPalette.primaryDark,
    secondary: PicPalette.primaryDark,
    onSecondary: Colors.white,
    secondaryContainer: PicPalette.primaryLight,
    onSecondaryContainer: PicPalette.primaryDark,
    tertiary: PicPalette.aiPrimary,
    onTertiary: Colors.white,
    tertiaryContainer: PicPalette.aiLight,
    onTertiaryContainer: PicPalette.aiDark,
    error: PicPalette.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFBE9EB),
    onErrorContainer: Color(0xFF7A1F29),
    surface: PicPalette.surface,
    onSurface: PicPalette.textPrimary,
    onSurfaceVariant: PicPalette.textSecondary,
    surfaceDim: Color(0xFFEFE9EC),
    surfaceBright: PicPalette.surface,
    surfaceContainerLowest: PicPalette.surface,
    surfaceContainerLow: PicPalette.background,
    surfaceContainer: PicPalette.surfaceMuted,
    surfaceContainerHigh: Color(0xFFEFE9EC),
    surfaceContainerHighest: Color(0xFFE8DFE4),
    outline: Color(0xFF8A9690),
    outlineVariant: PicPalette.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PicPalette.textPrimary,
    onInverseSurface: PicPalette.background,
    inversePrimary: PicPalette.accent,
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: PicPalette.accent,
    onPrimary: PicPalette.darkOnPrimary,
    primaryContainer: PicPalette.darkPrimaryContainer,
    onPrimaryContainer: PicPalette.accent,
    secondary: PicPalette.accent,
    onSecondary: PicPalette.darkOnPrimary,
    secondaryContainer: PicPalette.darkPrimaryContainer,
    onSecondaryContainer: PicPalette.accent,
    tertiary: PicPalette.darkAiPrimary,
    onTertiary: Color(0xFF1E1840),
    tertiaryContainer: PicPalette.darkAiContainer,
    onTertiaryContainer: Color(0xFFDCD5FB),
    error: PicPalette.darkError,
    onError: Color(0xFF3B0E14),
    errorContainer: Color(0xFF3F1F24),
    onErrorContainer: Color(0xFFF6C9CE),
    surface: PicPalette.darkSurface,
    onSurface: PicPalette.darkTextPrimary,
    onSurfaceVariant: PicPalette.darkTextSecondary,
    surfaceDim: PicPalette.darkBackground,
    surfaceBright: PicPalette.darkSurfaceElevated,
    surfaceContainerLowest: Color(0xFF0D1311),
    surfaceContainerLow: PicPalette.darkBackground,
    surfaceContainer: PicPalette.darkSurfaceElevated,
    surfaceContainerHigh: Color(0xFF392E37),
    surfaceContainerHighest: Color(0xFF433640),
    outline: Color(0xFF6E7D74),
    outlineVariant: PicPalette.darkBorder,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: PicPalette.darkTextPrimary,
    onInverseSurface: PicPalette.darkBackground,
    inversePrimary: PicPalette.primary,
    surfaceTint: Colors.transparent,
  );

  /// Escala tipográfica (Inter). Texto principal em 16 px; rótulos e textos
  /// auxiliares com no mínimo 13–14 px, sem caixa alta. Números em destaque
  /// usam algarismos tabulares.
  static TextTheme _text(ColorScheme s, PicColors p) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
      double spacing = 0,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color ?? s.onSurface,
    );
    return TextTheme(
      displayLarge: style(36, FontWeight.w600, 1.15, spacing: -0.5),
      displayMedium: style(32, FontWeight.w600, 1.15, spacing: -0.5),
      displaySmall: style(28, FontWeight.w600, 1.2, spacing: -0.3),
      headlineLarge: style(30, FontWeight.w600, 1.2, spacing: -0.4),
      headlineMedium: style(26, FontWeight.w600, 1.25, spacing: -0.3),
      headlineSmall: style(22, FontWeight.w600, 1.3, spacing: -0.2),
      titleLarge: style(20, FontWeight.w600, 1.3, spacing: -0.1),
      titleMedium: style(18, FontWeight.w600, 1.35),
      titleSmall: style(16, FontWeight.w600, 1.4),
      bodyLarge: style(16, FontWeight.w400, 1.5),
      bodyMedium: style(16, FontWeight.w400, 1.5),
      bodySmall: style(14, FontWeight.w400, 1.45, color: p.textSecondary),
      labelLarge: style(16, FontWeight.w600, 1.3),
      labelMedium: style(14, FontWeight.w500, 1.3),
      labelSmall: style(13, FontWeight.w500, 1.3, color: p.textSecondary),
    );
  }

  static ThemeData _build(ColorScheme s, PicColors p) {
    final text = _text(s, p);
    final isDark = s.brightness == Brightness.dark;
    final background = isDark
        ? PicPalette.darkBackground
        : PicPalette.background;
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: Space.xl,
      vertical: Space.md,
    );
    final buttonText = text.labelLarge;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.control,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: s.brightness,
      colorScheme: s,
      fontFamily: fontFamily,
      textTheme: text,
      extensions: [p],
      scaffoldBackgroundColor: background,
      canvasColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: s.onSurfaceVariant, size: 24),
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: s.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: p.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
        minVerticalPadding: Space.sm,
        shape: const RoundedRectangleBorder(borderRadius: Radii.control),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          foregroundColor: s.onSurface,
          side: BorderSide(color: p.border, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: s.primary,
        foregroundColor: s.onPrimary,
        extendedTextStyle: buttonText,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.lg)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: s.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: s.primary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: s.error),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(s.primary, 2),
        errorBorder: border(s.error),
        focusedErrorBorder: border(s.error, 2),
        disabledBorder: border(p.border.withValues(alpha: 0.5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: s.surface,
        selectedColor: p.brandContainer,
        side: BorderSide(color: p.border),
        labelStyle: text.labelMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.brandContainer,
          selectedForegroundColor: p.onBrandContainer,
          side: BorderSide(color: p.border),
          textStyle: text.labelMedium,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.brandContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? p.onBrandContainer
                : s.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? s.primary
                : s.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: s.onSurface,
        unselectedLabelColor: s.onSurfaceVariant,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: s.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.xl)),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: Radii.control),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: p.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : s.outline,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.control,
          side: BorderSide(color: p.border),
        ),
      ),
    );
  }
}
