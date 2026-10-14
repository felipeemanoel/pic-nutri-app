import 'package:flutter/material.dart';

import 'pic_colors.dart';
import 'tokens.dart';

/// Símbolo do PicNutri: um "P" cujo bojo é uma folha, com a nervura vazada
/// subindo como uma linha de evolução. Mesma geometria de
/// `tool/brand/symbol.py` (grade de 1024), que gera os ícones do app.
class PicNutriSymbol extends StatelessWidget {
  const PicNutriSymbol({super.key, this.size = 48, this.color});

  final double size;

  /// Cor do símbolo (padrão: cor primária do tema).
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'PicNutri',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SymbolPainter(color ?? Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

/// Ícone do app: símbolo branco sobre o quadrado esmeralda.
class PicNutriAppIcon extends StatelessWidget {
  const PicNutriAppIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: PicPalette.primary,
      borderRadius: BorderRadius.circular(size * 232 / 1024),
    ),
    child: PicNutriSymbol(size: size, color: Colors.white),
  );
}

/// Símbolo + nome, para login, splash e cabeçalhos de marca.
class PicNutriWordmark extends StatelessWidget {
  const PicNutriWordmark({
    super.key,
    this.iconSize = 56,
    this.showTagline = false,
  });

  final double iconSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PicNutriAppIcon(size: iconSize),
        SizedBox(height: iconSize * 0.25),
        Text(
          'PicNutri',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Sua evolução, no seu ritmo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024;
    canvas
      ..save()
      ..scale(s)
      ..translate(0, 20)
      ..saveLayer(const Rect.fromLTWH(0, -20, 1024, 1024), Paint());

    final fill = Paint()..color = color;
    final stem = Path()
      ..moveTo(318, 300)
      ..lineTo(428, 300)
      ..lineTo(428, 712)
      ..arcToPoint(const Offset(318, 712), radius: const Radius.circular(55))
      ..close();
    final leaf = Path()
      ..moveTo(318, 300)
      ..cubicTo(318, 270, 340, 252, 372, 250)
      ..lineTo(706, 214)
      ..cubicTo(740, 420, 650, 590, 428, 592)
      ..lineTo(318, 592)
      ..close();
    canvas
      ..drawPath(stem, fill)
      ..drawPath(leaf, fill);

    // Nervura vazada (recorta o símbolo, deixando o fundo aparecer).
    final rib = Path()
      ..moveTo(470, 524)
      ..cubicTo(560, 500, 640, 420, 676, 268);
    canvas
      ..drawPath(
        rib,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30
          ..strokeCap = StrokeCap.round,
      )
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_SymbolPainter old) => old.color != color;
}
