import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../symptoms/data/symptom_models.dart';
import '../../symptoms/data/symptom_repository.dart';
import '../application/medication_overview.dart';
import '../domain/medication_schedule.dart';

/// "Nível estimado": curva do medicamento no organismo calculada a partir das
/// aplicações registradas, com os sintomas marcados no tempo. Sempre com o
/// aviso de que é uma estimativa.
class MedicationLevelCard extends ConsumerStatefulWidget {
  const MedicationLevelCard({super.key, required this.overview});

  final MedicationOverview overview;

  @override
  ConsumerState<MedicationLevelCard> createState() =>
      _MedicationLevelCardState();
}

class _MedicationLevelCardState extends ConsumerState<MedicationLevelCard> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final level = widget.overview.level;
    if (level == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final from = now.subtract(Duration(days: _days));
    final points = level.series(
      from,
      now,
      step: Duration(hours: _days <= 7 ? 2 : (_days <= 30 ? 6 : 12)),
    );
    final current = MedicationLevel.rounded(level.at(now));
    final symptoms =
        (ref.watch(levelSymptomsProvider).value ?? const <SymptomItem>[])
            .where((s) => s.occurredAt.isAfter(from))
            .toList();
    final doses = level.doses.where((d) => d.takenAt.isAfter(from)).toList();
    final pic = context.pic;

    double x(DateTime t) => t.difference(from).inMinutes / 60;
    final maxY = points.fold<double>(0, (m, p) => p.mg > m ? p.mg : m);
    final top = maxY <= 0 ? 1.0 : maxY * 1.2;
    final spots = [for (final p in points) FlSpot(x(p.at), p.mg)];
    final symptomSpots = [
      for (final s in symptoms) FlSpot(x(s.occurredAt), top * 0.04),
    ];
    final lastSymptom = symptoms.isEmpty
        ? null
        : symptoms.reduce((a, b) => a.occurredAt.isAfter(b.occurredAt) ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Nível estimado',
                        style: context.text.titleMedium,
                      ),
                    ),
                    Text(
                      widget.overview.medication.name,
                      style: context.text.bodySmall?.copyWith(
                        color: pic.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '~${Fmt.decimal(current)}',
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: ' mg',
                      style: context.text.titleSmall?.copyWith(
                        color: pic.textSecondary,
                      ),
                    ),
                  ],
                ),
                semanticsLabel:
                    'Cerca de ${Fmt.decimal(current)} miligramas, estimativa',
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: 7, label: Text('7 dias')),
              ButtonSegment(value: 30, label: Text('30 dias')),
              ButtonSegment(value: 90, label: Text('90 dias')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          const SizedBox(height: Space.lg),
          Semantics(
            label:
                'Gráfico do nível estimado nos últimos $_days dias, com ${doses.length} aplicações e ${symptoms.length} sintomas registrados.',
            excludeSemantics: true,
            child: SizedBox(
              height: 170,
              child: LineChart(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Motion.medium,
                LineChartData(
                  minX: 0,
                  maxX: x(now),
                  minY: 0,
                  maxY: top,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: top / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: pic.chartGrid,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      for (final d in doses)
                        VerticalLine(
                          x: x(d.takenAt),
                          color: pic.chartLine.withValues(alpha: 0.35),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: x(now) / 2,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value >= x(now) - 1
                                ? 'hoje'
                                : Fmt.dayMonth(
                                    from.add(
                                      Duration(minutes: (value * 60).round()),
                                    ),
                                  ).replaceAll('.', ''),
                            style: context.text.labelSmall?.copyWith(
                              color: pic.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => context.colors.inverseSurface,
                      fitInsideHorizontally: true,
                      getTooltipItems: (touched) => [
                        for (final t in touched)
                          t.barIndex == 0
                              ? LineTooltipItem(
                                  '~${Fmt.decimal(MedicationLevel.rounded(t.y))} mg\n',
                                  context.text.labelLarge!.copyWith(
                                    color: context.colors.onInverseSurface,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: Fmt.dayMonth(
                                        from.add(
                                          Duration(minutes: (t.x * 60).round()),
                                        ),
                                      ).replaceAll('.', ''),
                                      style: context.text.labelSmall?.copyWith(
                                        color: context.colors.onInverseSurface,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      color: pic.chartLine,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        checkToShowDot: (spot, bar) => spot == bar.spots.last,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 4,
                          color: pic.chartLine,
                          strokeWidth: 2,
                          strokeColor: context.colors.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            pic.chartLine.withValues(alpha: 0.28),
                            pic.chartLine.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                    if (symptomSpots.isNotEmpty)
                      LineChartBarData(
                        spots: symptomSpots,
                        barWidth: 0,
                        color: Colors.transparent,
                        dotData: FlDotData(
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 4,
                            color: pic.warning,
                            strokeWidth: 1.5,
                            strokeColor: context.colors.surface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.lg,
            runSpacing: Space.xs,
            children: [
              _Legend(
                color: pic.chartLine,
                label: 'Aplicações (linhas)',
                dashed: true,
              ),
              if (symptoms.isNotEmpty)
                _Legend(color: pic.warning, label: 'Sintomas'),
            ],
          ),
          if (lastSymptom != null) ...[
            const SizedBox(height: Space.md),
            Text(
              'Último sintoma: ${lastSymptom.label}'
              '${lastSymptom.intensityLabel.isEmpty ? '' : ' (${lastSymptom.intensityLabel.toLowerCase()})'}'
              ' · ${Fmt.relativeDayTime(lastSymptom.occurredAt)}',
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: Space.md),
          Text(
            'Estimativa feita com a meia-vida da bula (${level.ingredient.name}) e as doses que você registrou. '
            'Não é exame e não substitui a orientação do seu médico.',
            style: context.text.bodySmall?.copyWith(color: pic.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: dashed ? 2 : 10,
        height: dashed ? 12 : 10,
        decoration: BoxDecoration(
          color: dashed ? color.withValues(alpha: 0.5) : color,
          shape: dashed ? BoxShape.rectangle : BoxShape.circle,
        ),
      ),
      const SizedBox(width: Space.xs),
      Text(label, style: context.text.labelSmall),
    ],
  );
}
