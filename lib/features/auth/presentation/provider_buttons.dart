import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/design/design_system.dart';

/// Botões dos provedores conforme as diretrizes de cada marca:
/// - Google: fundo branco, borda cinza, logotipo "G" colorido;
/// - Facebook: variante branca, com o círculo azul #1877F2 e o "f" branco;
/// - Apple: botão oficial do pacote sign_in_with_apple (preto, ou branco no tema escuro).
/// Mesma altura e cantos para todos; o texto segue o padrão "Continuar com ...".
class ProviderButton extends StatelessWidget {
  const ProviderButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String provider;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const height = 52.0;
  static const _radius = BorderRadius.all(Radius.circular(14));
  static const facebookBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final busy = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: provider == 'google'
                  ? const Color(0xFF4285F4)
                  : facebookBlue,
              semanticsLabel: 'Entrando',
            ),
          )
        : null;

    if (provider == 'apple') {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        child: Opacity(
          opacity: onPressed == null && !loading ? 0.5 : 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SignInWithAppleButton(
                text: label,
                height: height,
                borderRadius: _radius,
                style: dark
                    ? SignInWithAppleButtonStyle.white
                    : SignInWithAppleButtonStyle.black,
                onPressed: onPressed ?? () {},
              ),
              if (busy != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: dark ? Colors.white : Colors.black,
                      borderRadius: _radius,
                    ),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: dark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final google = provider == 'google';
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF14201E),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0x6114201E),
          side: const BorderSide(color: Color(0xFFC9D0CE)),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          textStyle: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy ?? (google ? const _GoogleLogo() : const _FacebookLogo()),
            const SizedBox(width: 18),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// "G" do Google desenhado nas quatro cores da marca.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 24,
    child: CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = math.pi / 180;
    canvas
      ..drawArc(
        rect,
        -40 * deg,
        -80 * deg,
        false,
        arc(const Color(0xFFEA4335)),
      ) // vermelho (topo)
      ..drawArc(
        rect,
        -120 * deg,
        -100 * deg,
        false,
        arc(const Color(0xFFFBBC05)),
      ) // amarelo (esquerda)
      ..drawArc(
        rect,
        140 * deg,
        -100 * deg,
        false,
        arc(const Color(0xFF34A853)),
      ) // verde (base)
      ..drawArc(
        rect,
        40 * deg,
        -40 * deg,
        false,
        arc(const Color(0xFF4285F4)),
      ); // azul (direita)
    // Barra horizontal do "G".
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width / 2,
        stroke,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "f" do Facebook: círculo azul da marca com a letra branca.
class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.bottomCenter,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      color: ProviderButton.facebookBlue,
      shape: BoxShape.circle,
    ),
    child: const Text(
      'f',
      style: TextStyle(
        color: Colors.white,
        fontSize: 23,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
    ),
  );
}
