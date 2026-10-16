import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/features.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/progress_widgets.dart';
import '../../../shared/widgets/state_views.dart';
import '../../plan/data/plan_repository.dart';
import '../data/report_models.dart';
import '../data/report_repository.dart';

/// Relatórios semanal e mensal: médias, metas atingidas, água, peso e
/// comparação com o período anterior. Exportação conforme o plano.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _period = 'week';
  DateTime _reference = DateTime.now();
  bool _exporting = false;

  ReportQuery get _query => (
    period: _period,
    reference: DateTime(_reference.year, _reference.month, _reference.day),
  );

  void _shift(int direction) => setState(() {
    _reference = _period == 'week'
        ? _reference.add(Duration(days: 7 * direction))
        : DateTime(_reference.year, _reference.month + direction, 1);
  });

  bool get _isCurrent {
    final now = DateTime.now();
    if (_period == 'month') return _reference.year == now.year && _reference.month == now.month;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final refMonday = _reference.subtract(Duration(days: _reference.weekday - 1));
    return DateUtils.isSameDay(monday, refMonday);
  }

  /// Confere no plano se relatórios estão incluídos; se não, oferece os planos.
  Future<bool> _reportsAllowed() async {
    CurrentPlan? plan;
    try {
      plan = await ref.read(currentPlanProvider.future);
    } on Object {
      plan = null; // Sem o plano, a própria API responde se o recurso está disponível.
    }
    final usage = plan?.usageOf('report_export');
    if (!mounted) return false;
    if (usage != null && usage.limit == 0) {
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_outlined),
          title: const Text('Relatórios para baixar'),
          content: const Text('O relatório para consulta (PDF) e a exportação em planilha fazem parte do plano Premium.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Agora não')),
            FilledButton(
              onPressed: () {
                Navigator.of(dialog).pop();
                context.push(AppRoutes.plan);
              },
              child: const Text('Ver planos'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _export(PeriodReport report) async {
    if (!await _reportsAllowed() || !mounted) return;
    setState(() => _exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/picnutri-relatorio-${Fmt.apiDate(report.from)}.csv';
      await ref.read(reportRepositoryProvider).export(_query, path);
      ref.invalidate(currentPlanProvider);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: 'text/csv')], subject: 'Relatório PicNutri'),
      );
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _consultationPdf() async {
    final days = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.sm),
              child: Text('Período do relatório', style: Theme.of(sheet).textTheme.titleMedium),
            ),
            for (final (d, label) in const [(30, 'Últimos 30 dias'), (90, 'Últimos 3 meses'), (180, 'Últimos 6 meses')])
              ListTile(title: Text(label), onTap: () => Navigator.of(sheet).pop(d)),
          ],
        ),
      ),
    );
    if (days == null || !mounted) return;
    if (!await _reportsAllowed() || !mounted) return;
    setState(() => _exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/picnutri-relatorio-consulta-${Fmt.apiDate(DateTime.now())}.pdf';
      await ref.read(reportRepositoryProvider).consultationPdf(days, path);
      ref.invalidate(currentPlanProvider);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: 'application/pdf')], subject: 'Relatório PicNutri para consulta'),
      );
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(periodReportProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: _exporting
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            onPressed: _exporting || report.value == null ? null : () => _export(report.value!),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(periodReportProvider(_query).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
          children: [
            SectionCard(
              title: 'Relatório para consulta',
              icon: Icons.picture_as_pdf_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppFeatures.medical
                        ? 'PDF com peso, medidas, sintomas, alimentação e, se você registra, as aplicações do medicamento. '
                            'Leve para o médico ou nutricionista. Você escolhe com quem compartilhar.'
                        : 'PDF com peso, medidas, sintomas e alimentação. '
                            'Leve para o médico ou nutricionista. Você escolhe com quem compartilhar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _consultationPdf,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Gerar PDF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Semana')),
                  ButtonSegment(value: 'month', label: Text('Mês')),
                ],
                selected: {_period},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() {
                  _period = v.first;
                  _reference = DateTime.now();
                }),
              ),
            ),
            const SizedBox(height: Space.sm),
            report.maybeWhen(
              data: (r) => _PeriodNavigator(
                label: r.period == 'month'
                    ? _capitalize(Fmt.monthYear(r.from))
                    : '${Fmt.dayMonth(r.from)} – ${Fmt.dayMonth(r.to)}',
                onPrevious: () => _shift(-1),
                onNext: _isCurrent ? null : () => _shift(1),
              ),
              orElse: () => const SizedBox(height: 48),
            ),
            AsyncValueView<PeriodReport>(
              value: report,
              onRetry: () => ref.invalidate(periodReportProvider(_query)),
              loading: const Column(children: [SkeletonCard(lines: 3), SizedBox(height: Space.md), SkeletonCard()]),
              data: (r) => _ReportBody(report: r),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({required this.label, required this.onPrevious, required this.onNext});

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(tooltip: 'Período anterior', icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
      Expanded(child: Text(label, style: context.text.titleMedium, textAlign: TextAlign.center)),
      IconButton(tooltip: 'Próximo período', icon: const Icon(Icons.chevron_right), onPressed: onNext),
    ],
  );
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final PeriodReport report;

  @override
  Widget build(BuildContext context) {
    final s = report.summary;
    final p = report.previous;
    if (s.daysLogged == 0 && report.days.every((d) => d.waterMl == 0)) {
      return const Padding(
        padding: EdgeInsets.only(top: Space.xxl),
        child: EmptyState(
          icon: Icons.insert_chart_outlined,
          title: 'Sem registros neste período',
          message: 'Registre refeições e água para ver médias, metas atingidas e comparações aqui.',
        ),
      );
    }

    final pic = context.pic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Média por dia registrado', style: context.text.labelSmall),
              MetricValue(
                value: s.avgEnergyKcal == null ? '—' : Fmt.integer(s.avgEnergyKcal!),
                unit: 'kcal',
                large: true,
              ),
              Text(
                '${s.daysLogged} de ${report.daysElapsed} dias com refeições registradas'
                '${report.goalKcal == null ? '' : ' · meta ${Fmt.kcal(report.goalKcal!)}'}',
                style: context.text.bodySmall,
              ),
              if (s.avgEnergyKcal != null && p.avgEnergyKcal != null) ...[
                const SizedBox(height: Space.sm),
                _Comparison(
                  current: s.avgEnergyKcal!,
                  previous: p.avgEnergyKcal!,
                  unit: 'kcal',
                  label: report.period == 'week' ? 'semana anterior' : 'mês anterior',
                ),
              ],
              const SizedBox(height: Space.lg),
              MacroSummary(
                proteinG: s.avgProteinG ?? 0,
                carbsG: s.avgCarbsG ?? 0,
                fatG: s.avgFatG ?? 0,
                proteinGoal: report.goalProteinG,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Calorias por dia'),
        AppCard(
          child: DailyBarChart(
            days: [for (final d in report.days) (d.date, d.energyKcal)],
            goal: (report.goalKcal ?? 0).toDouble(),
            color: context.colors.primary,
            semanticLabel: 'Calorias por dia no período',
            dayLabel: report.period == 'week' ? (d) => _weekday(d) : null,
          ),
        ),
        const SectionHeader(title: 'Metas atingidas'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GoalRow(
                label: 'Calorias (±10% da meta)',
                days: report.days.map((d) => d.caloriesMet).toList(),
                count: s.daysCaloriesMet,
                hasGoal: report.goalKcal != null,
                color: context.colors.primary,
              ),
              const Divider(height: Space.xxl),
              _GoalRow(
                label: 'Proteínas (90% da meta)',
                days: report.days.map((d) => d.proteinMet).toList(),
                count: s.daysProteinMet,
                hasGoal: report.goalProteinG != null,
                color: pic.protein,
              ),
              const Divider(height: Space.xxl),
              _GoalRow(
                label: 'Água',
                days: report.days.map<bool?>((d) => d.waterMet).toList(),
                count: s.daysWaterMet,
                hasGoal: true,
                color: pic.water,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Água e peso'),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Stat(
                  value: s.avgWaterMl == null ? '—' : Fmt.ml(s.avgWaterMl!),
                  label: 'média nos dias com registro',
                ),
              ),
              Expanded(
                child: Stat(
                  value: report.weightChangeKg == null ? '—' : signedKg(report.weightChangeKg),
                  label: report.weightChangeKg == null ? 'poucos registros de peso' : 'variação no período',
                ),
              ),
            ],
          ),
        ),
        if (report.mealsByType.isNotEmpty) ...[
          const SectionHeader(title: 'Refeições registradas'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                for (final (label, count) in report.mealsByType)
                  ListTile(
                    dense: true,
                    title: Text(label),
                    trailing: Text('$count', style: context.text.titleSmall),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        Text(
          'Os critérios de meta são referências informativas e não substituem orientação profissional.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _weekday(DateTime d) => const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][d.weekday - 1];
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.current, required this.previous, required this.unit, required this.label});

  final double current;
  final double previous;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final text = diff.abs() < 1
        ? 'Igual à $label'
        : '${diff > 0 ? '+' : '−'}${Fmt.integer(diff.abs())} $unit em relação à $label';
    return Row(
      children: [
        Icon(
          diff.abs() < 1 ? Icons.drag_handle : (diff > 0 ? Icons.north_east : Icons.south_east),
          size: 16,
          color: context.pic.textSecondary,
        ),
        const SizedBox(width: Space.xs),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    );
  }
}

/// Uma linha de metas por dia: bolinha cheia (atingida), vazada (não) ou
/// tracejada (sem registro/meta). Texto com o total para leitores de tela.
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.label,
    required this.days,
    required this.count,
    required this.hasGoal,
    required this.color,
  });

  final String label;
  final List<bool?> days;
  final int count;
  final bool hasGoal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.labelMedium)),
            Text(
              hasGoal ? '$count ${count == 1 ? 'dia' : 'dias'}' : 'sem meta definida',
              style: context.text.bodySmall,
            ),
          ],
        ),
        if (hasGoal) ...[
          const SizedBox(height: Space.sm),
          ExcludeSemantics(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final met in days)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: met == true ? color : null,
                      border: Border.all(
                        color: met == null ? pic.border : color,
                        width: met == null ? 1 : 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
