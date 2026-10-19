import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../pic_colors.dart';
import '../tokens.dart';
import 'progress_ring.dart';

/// Valor numérico em destaque com unidade menor (algarismos tabulares).
class MetricValue extends StatelessWidget {
  const MetricValue({
    super.key,
    required this.value,
    this.unit,
    this.large = false,
    this.color,
  });

  final String value;
  final String? unit;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = large ? context.text.displaySmall : context.text.headlineSmall;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: base?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: context.text.bodyMedium?.copyWith(
                color: context.pic.textSecondary,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Bloco compacto de indicador: ícone, rótulo, valor e barra opcional.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.caption,
    this.progress,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String? caption;
  final double? progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: tone),
            const SizedBox(width: Space.xs),
            Flexible(
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        MetricValue(value: value, unit: unit),
        if (progress != null) ...[
          const SizedBox(height: Space.sm),
          ProgressBar(progress: progress, color: tone, height: 6),
        ],
        if (caption != null) ...[
          const SizedBox(height: Space.xs),
          Text(caption!, style: context.text.bodySmall),
        ],
      ],
    );
  }
}

/// Proteínas, carboidratos e gorduras, com cor, rótulo e valor (a cor nunca
/// é a única informação).
class MacroSummary extends StatelessWidget {
  const MacroSummary({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final int? proteinGoal;
  final int? carbsGoal;
  final int? fatGoal;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return Row(
      children: [
        Expanded(child: _Macro('Proteínas', proteinG, proteinGoal, p.protein)),
        const SizedBox(width: Space.md),
        Expanded(child: _Macro('Carboidratos', carbsG, carbsGoal, p.carbs)),
        const SizedBox(width: Space.md),
        Expanded(child: _Macro('Gorduras', fatG, fatGoal, p.fat)),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value, this.goal, this.color);

  final String label;
  final double value;
  final int? goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    return Semantics(
      label: hasGoal
          ? '$label: ${Fmt.grams(value)} de ${goal}g'
          : '$label: ${Fmt.grams(value)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Flexible(
                  child: Text(
                    label,
                    style: context.text.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Text(
              hasGoal ? '${Fmt.decimal(value)}/${goal}g' : Fmt.grams(value),
              style: context.text.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.xs),
            ProgressBar(
              progress: hasGoal ? value / goal! : (value > 0 ? 1 : 0),
              color: color,
              height: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de ação rápida (ícone em destaque + rótulo), mínimo de 48 dp.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.ai = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Ação de IA: usa a identidade roxa.
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    final fg = ai ? p.ai : context.colors.primary;
    final bg = ai ? p.aiContainer : p.brandContainer;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.card,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Space.sm,
              horizontal: Space.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: fg.withValues(alpha: 0.12)),
                  ),
                  child: Icon(icon, color: fg),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  label,
                  style: context.text.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
