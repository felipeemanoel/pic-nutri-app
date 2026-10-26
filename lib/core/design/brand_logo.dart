import 'package:flutter/material.dart';

import 'pic_colors.dart';

/// Monograma da nova marca, derivado do PNG oficial.
class PicNutriSymbol extends StatelessWidget {
  const PicNutriSymbol({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/picnutri_monogram.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: color,
    semanticLabel: 'PicNutri',
  );
}

/// Ícone de instalação aprovado, também usado em contextos compactos.
class PicNutriAppIcon extends StatelessWidget {
  const PicNutriAppIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: Image.asset(
      'assets/brand/app_icon_source.png',
      width: size,
      height: size,
      semanticLabel: 'PicNutri',
    ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/picnutri_logo_square_trimmed.png',
          width: (iconSize * 3).clamp(140.0, 216.0),
          fit: BoxFit.contain,
          semanticLabel: 'PicNutri',
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Sua evolução, no seu ritmo.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.pic.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Logo horizontal oficial em PNG, com contraste para o tema atual.
class PicNutriHorizontalLogo extends StatelessWidget {
  const PicNutriHorizontalLogo({super.key, this.width = 156});

  final double width;

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).brightness == Brightness.dark
        ? 'white'
        : 'green';
    return Image.asset(
      'assets/brand/picnutri_wordmark_$variant.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'PicNutri',
      filterQuality: FilterQuality.medium,
    );
  }
}
