import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';
import '../../core/utils/formatters.dart';

/// Gráfico de linha simples para séries por data (ex.: peso).
class DateLineChart extends StatelessWidget {
  const DateLineChart({
    super.key,
    required this.points,
    required this.unit,
    this.height = 180,
    this.target,
    this.markers = const [],
  });

  final List<(DateTime, double)> points;
  final String unit;
  final double height;

  /// Linha de referência opcional (ex.: peso desejado).
  final double? target;

  /// Datas marcadas com linhas verticais (ex.: aplicações do medicamento).
  final List<DateTime> markers;

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final first = points.first.$1;
    final spots = [
      for (final (date, value) in points)
        FlSpot(date.difference(first).inDays.toDouble(), value),
    ];
    final values = [for (final p in points) p.$2, ?target];
    final minY = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 1;
    final maxX = spots.last.x == 0 ? 1.0 : spots.last.x;

    return Semantics(
      label:
          'Gráfico de ${points.length} registros, de ${Fmt.decimal(points.first.$2)} a ${Fmt.decimal(points.last.$2)} $unit',
      child: SizedBox(
        height: height,
        child: LineChart(
          duration: reduceMotion ? Duration.zero : Motion.medium,
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: pic.chartGrid, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (target != null)
                  HorizontalLine(
                    y: target!,
                    color: pic.chartReference,
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
              ],
              verticalLines: [
                for (final m in markers)
                  if (!m.isBefore(first) && m.difference(first).inDays <= maxX)
                    VerticalLine(
                      x: m.difference(first).inDays.toDouble(),
                      color: pic.ai.withValues(alpha: 0.55),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Fmt.decimal(value),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxX / 3).clamp(1, double.infinity),
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Fmt.dayMonth(first.add(Duration(days: value.round()))),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: pic.chartLine,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: spots.length <= 31,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: pic.chartLine,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      pic.chartLine.withValues(alpha: 0.20),
                      pic.chartLine.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barras diárias com linha de meta (ex.: água da semana).
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.days,
    required this.goal,
    this.height = 160,
    this.color,
    this.semanticLabel,
    this.dayLabel,
  });

  final List<(DateTime, double)> days;

  /// Linha de meta (0 = sem linha).
  final double goal;
  final double height;

  /// Cor das barras (padrão: água).
  final Color? color;
  final String? semanticLabel;

  /// Rótulo do eixo (padrão: dia do mês).
  final String Function(DateTime day)? dayLabel;

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxValue = [
      goal,
      1.0,
      for (final d in days) d.$2,
    ].reduce((a, b) => a > b ? a : b);
    return Semantics(
      label: semanticLabel ?? 'Consumo de água nos últimos ${days.length} dias',
      child: SizedBox(
        height: height,
        child: BarChart(
          duration: reduceMotion ? Duration.zero : Motion.medium,
          BarChartData(
            maxY: maxValue * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (goal > 0)
                  HorizontalLine(
                    y: goal,
                    color: pic.chartReference,
                    strokeWidth: 1,
                    dashArray: [6, 4],
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
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        dayLabel?.call(days[index].$1) ??
                            '${days[index].$1.day}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: days[i].$2,
                      width: days.length > 14 ? 6 : 16,
                      color: goal <= 0 || days[i].$2 >= goal
                          ? (color ?? pic.water)
                          : (color ?? pic.water).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha mínima, sem eixos, para resumos (ex.: peso no painel inicial).
/// Só deve ser usada com pelo menos dois registros reais.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.points,
    this.height = 56,
    this.semanticLabel,
  });

  final List<(DateTime, double)> points;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);
    final pic = context.pic;
    final first = points.first.$1;
    final spots = [
      for (final (date, value) in points)
        FlSpot(date.difference(first).inDays.toDouble(), value),
    ];
    final values = [for (final p in points) p.$2];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    // Margem mínima de 1 kg: oscilações pequenas não parecem grandes.
    final pad = ((maxY - minY) < 2 ? (2 - (maxY - minY)) / 2 : 0) + 0.2;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LineChart(
            duration: Duration.zero,
            LineChartData(
              minY: minY - pad,
              maxY: maxY + pad,
              minX: 0,
              maxX: spots.last.x == 0 ? 1 : spots.last.x,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: pic.chartLine,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    checkToShowDot: (spot, bar) => spot == bar.spots.last,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 3.5,
                      color: pic.chartLine,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        pic.chartLine.withValues(alpha: 0.20),
                        pic.chartLine.withValues(alpha: 0.01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
