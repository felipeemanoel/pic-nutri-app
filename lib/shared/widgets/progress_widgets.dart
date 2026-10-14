import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';
import '../../core/utils/formatters.dart';

/// Barra de progresso rotulada (valor / meta). Sem meta, mostra só o valor.
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.goal,
    this.color,
  });

  final String label;
  final double value;
  final String unit;
  final num? goal;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    final valueText = '${Fmt.decimal(value)} $unit';

    return Semantics(
      label: hasGoal
          ? '$label: $valueText de ${Fmt.decimal(goal!)} $unit'
          : '$label: $valueText',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: context.text.labelMedium)),
                Text(
                  hasGoal
                      ? '$valueText / ${Fmt.decimal(goal!)} $unit'
                      : valueText,
                  style: context.text.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            ProgressBar(progress: hasGoal ? value / goal! : 0, color: color),
          ],
        ),
      ),
    );
  }
}

/// Número de destaque com rótulo pequeno embaixo.
class Stat extends StatelessWidget {
  const Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: context.text.titleLarge?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      Text(label, style: context.text.bodySmall),
    ],
  );
}

/// Variação com sinal e cor neutra (não reforça perda de peso como "boa").
String signedKg(double? change) {
  if (change == null) return '—';
  final sign = change > 0 ? '+' : (change < 0 ? '−' : '');
  return '$sign${Fmt.kg(change.abs())}';
}
