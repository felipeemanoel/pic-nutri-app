import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/design_system.dart';

/// Representação do volume total: inclusive copos parciais e última fração da meta.
class WaterCups extends StatelessWidget {
  const WaterCups({
    super.key,
    required this.totalMl,
    required this.goalMl,
    this.onAdd,
  });
  final int totalMl;
  final int goalMl;
  final ValueChanged<int>? onAdd;

  @override
  Widget build(BuildContext context) {
    if (goalMl <= 0) {
      return const Text('Defina uma meta para visualizar os copos.');
    }
    final unit = math.max(200, (goalMl / 20 / 50).ceil() * 50);
    final count = (goalMl / unit).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < count; i++)
              Builder(
                builder: (context) {
                  final capacity = math.min(unit, goalMl - i * unit);
                  final amount = (totalMl - i * unit).clamp(0, capacity);
                  final remaining = capacity - amount;
                  return Semantics(
                    label: 'Copo ${i + 1}: $amount de $capacity ml',
                    child: Tooltip(
                      message: remaining > 0
                          ? 'Registrar $remaining ml'
                          : '$capacity ml registrados',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onAdd == null || remaining == 0
                            ? null
                            : () => onAdd!(remaining),
                        child: SizedBox(
                          width: 44,
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: amount / capacity),
                              duration: const Duration(milliseconds: 350),
                              builder: (_, value, _) => CustomPaint(
                                painter: _CupPainter(value, context.pic.water),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Cada copo: $unit ml${goalMl % unit != 0 ? ' · último: ${goalMl % unit} ml' : ''}. Toque em um copo para registrar.',
          style: context.text.bodySmall,
        ),
        if (totalMl >= goalMl)
          Text('Meta do dia alcançada', style: context.text.labelLarge),
      ],
    );
  }
}

class _CupPainter extends CustomPainter {
  const _CupPainter(this.fill, this.color);
  final double fill;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(size.width - 1, 1)
      ..lineTo(size.width * .82, size.height - 1)
      ..lineTo(size.width * .18, size.height - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .08));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * (1 - fill),
        size.width,
        size.height * fill,
      ),
      Paint()..color = color.withValues(alpha: .85),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (fill == 0) {
      final p = Paint()
        ..color = color.withValues(alpha: .5)
        ..strokeWidth = 1.5;
      final c = Offset(size.width / 2, size.height / 2);
      canvas.drawLine(c - const Offset(4, 0), c + const Offset(4, 0), p);
      canvas.drawLine(c - const Offset(0, 4), c + const Offset(0, 4), p);
    }
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.fill != fill || old.color != color;
}
