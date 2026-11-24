import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Paleta oficial do PicNutri. Use pelos tokens semânticos
/// (`Theme.of(context).colorScheme` e `context.pic`), não diretamente nas telas.
///
/// Contraste (WCAG) validado pelos testes do Design System.
abstract final class PicPalette {
  // Marca. Verde-esmeralda profundo e sólido: transmite cuidado e segurança
  // (saúde) sem a leveza de um verde "menta"; branco sobre ele tem 6,5:1.
  static const primary = Color(0xFF0F6B4E);
  static const primaryDark = Color(0xFF0A4D38);
  static const primaryLight = Color(0xFFE4F2EA);
  static const accent = Color(0xFF6FD3A2);

  // Tema claro.
  // Neutros quase cinza (leve fundo verde): a cor fica para a marca e os dados.
  static const background = Color(0xFFF4F6F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF2F0);
  static const textPrimary = Color(0xFF121A17);
  static const textSecondary = Color(0xFF5A6661);
  static const border = Color(0xFFE3E8E5);

  // Semânticas (tema claro).
  static const success = Color(0xFF21865A);
  static const warning = Color(0xFFA87631);
  // Texto de alerta: o tom oficial tem contraste 3,6:1 no branco; para texto
  // pequeno usa-se este tom mais escuro (5,6:1).
  static const warningText = Color(0xFF8F5E14);
  static const error = Color(0xFFC43D4B);
  static const info = Color(0xFF547B91);

  // Inteligência artificial.
  static const aiPrimary = Color(0xFF7561D8);
  static const aiLight = Color(0xFFEEEAFE);
  static const aiDark = Color(0xFF5141A6);

  // Tema escuro.
  static const darkBackground = Color(0xFF121614);
  static const darkSurface = Color(0xFF1B201D);
  static const darkSurfaceElevated = Color(0xFF252B27);
  static const darkTextPrimary = Color(0xFFF2F6F3);
  static const darkTextSecondary = Color(0xFFB7C2BC);
  static const darkBorder = Color(0xFF343C37);
  static const darkOnPrimary = Color(0xFF0B2A1C);
  static const darkPrimaryContainer = Color(0xFF1E3A2C);
  static const darkSuccess = Color(0xFF5CC48E);
  static const darkWarning = Color(0xFFE0B25C);
  static const darkError = Color(0xFFE07A86);
  static const darkInfo = Color(0xFF6FA8EA);
  static const darkAiPrimary = Color(0xFFB3A6F5);
  static const darkAiContainer = Color(0xFF2A2547);

  // Macronutrientes (diferenciados também por rótulo e posição, nunca só pela cor).
  static const protein = Color(0xFF547B91);
  static const carbs = Color(0xFFA87631);
  static const fat = Color(0xFFC0583A);
  static const darkProtein = Color(0xFF6FA8EA);
  static const darkCarbs = Color(0xFFE0B25C);
  static const darkFat = Color(0xFFF0997C);

  // Água.
  static const water = Color(0xFF1A6FD1);
  static const darkWater = Color(0xFF6CC0EA);
}

/// Espaçamentos (múltiplos de 4).
abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Margem lateral padrão das telas.
  static const page = 20.0;

  /// Entre seções diferentes de uma tela (24–32 px). Elementos relacionados
  /// usam os espaços menores (sm/md).
  static const section = 28.0;

  /// Dentro dos cartões (16–20 px).
  static const card = 20.0;

  /// Espaço no fim de listas com botão flutuante.
  static const fabClearance = 96.0;
}

/// Raios de borda.
abstract final class Radii {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const sheet = 24.0;
  static const pill = 999.0;

  // Cantos de 20 nos cartões e 14 nos botões: firmes, menos "bolha".
  static const card = BorderRadius.all(Radius.circular(xl));
  static const control = BorderRadius.all(Radius.circular(md));
  static const button = BorderRadius.all(Radius.circular(14));
}

/// Durações e curvas das animações (curtas e funcionais).
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeOutCubic;
}

/// Sombras suaves, usadas só quando agregam hierarquia.
abstract final class Shadows {
  static const soft = [
    BoxShadow(color: Color(0x0F14201E), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
