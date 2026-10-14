import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pic_colors.dart';
import '../tokens.dart';

/// Anel de progresso (ex.: calorias do dia). A animação é curta e some quando
/// o sistema pede menos movimento.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 132,
    this.strokeWidth = 12,
    this.color,
    this.semanticLabel,
  });

  /// 0 a 1 (valores acima de 1 aparecem como anel completo).
  final double? progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final target = (progress ?? 0).clamp(0.0, 1.0);
    final ringColor = color ?? context.colors.primary;
    final track = context.pic.surfaceMuted;

    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: reduceMotion ? Duration.zero : Motion.slow,
          curve: Motion.curve,
          builder: (context, value, child) => CustomPaint(
            painter: _RingPainter(value, ringColor, track, strokeWidth),
            child: child,
          ),
          child: Center(child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, this.color, this.track, this.width);

  final double value;
  final Color color;
  final Color track;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(width / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Barra fina de progresso com cantos arredondados e animação curta.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 8,
  });

  final double? progress;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (progress ?? 0).clamp(0.0, 1.0)),
        duration: reduceMotion ? Duration.zero : Motion.slow,
        curve: Motion.curve,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: height,
          color: color ?? context.colors.primary,
          backgroundColor: context.pic.surfaceMuted,
        ),
      ),
    );
  }
}
