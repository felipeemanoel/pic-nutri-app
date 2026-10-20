import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../data/report_models.dart';
import '../data/report_repository.dart';

/// Semana atual (segunda a domingo) para o cartão do Início.
ReportQuery currentWeekQuery([DateTime? now]) {
  final today = now ?? DateTime.now();
  return (
    period: 'week',
    reference: DateTime(today.year, today.month, today.day),
  );
}

/// Textos do resumo semanal, em linguagem simples (função pura, testada).
///
/// Nunca interpreta dia sem registro como falta de alimentação, e só compara
/// com a semana anterior quando as duas têm registros suficientes.
class WeeklySummaryText {
  WeeklySummaryText(this.report);

  final PeriodReport report;

  static const minDaysToCompare = 3;

  bool get isEmpty => report.summary.daysLogged == 0;

  String get period =>
      '${Fmt.dayMonth(report.from)} a ${Fmt.dayMonth(report.to)}';

  String get status => report.inProgress ? 'Em andamento' : 'Concluída';

  String get title =>
      report.inProgress ? 'Sua semana até agora' : 'Resumo da semana';

  String get daysLogged {
    final n = report.summary.daysLogged;
    final total = report.daysElapsed;
    return report.inProgress
        ? '$n de $total ${total == 1 ? 'dia' : 'dias'} até agora com registros'
        : '$n de 7 dias com registros';
  }

  /// Metas configuradas, como frequência ("2 de 4 dias").
  List<String> get goals {
    final s = report.summary;
    final days = report.daysElapsed;
    return [
      if ((report.goalWaterMl ?? 0) > 0)
        'Meta de água: ${s.daysWaterMet} de $days ${days == 1 ? 'dia' : 'dias'}',
      if ((report.goalProteinG ?? 0) > 0)
        'Meta de proteína: ${s.daysProteinMet} de $days ${days == 1 ? 'dia' : 'dias'}',
    ];
  }

  /// Comparação só quando as duas semanas têm registros suficientes.
  String? get comparison {
    final now = report.summary.daysLogged;
    final before = report.previous.daysLogged;
    if (now < minDaysToCompare || before < minDaysToCompare) return null;
    return 'Semana anterior: $before ${before == 1 ? 'dia' : 'dias'} com registros';
  }

  /// Peso com pelo menos dois registros na semana (variação neutra, sem julgamento).
  String? get weight {
    final change = report.weightChangeKg;
    if (change == null) return null;
    final sign = change > 0 ? '+' : '';
    return 'Peso: variação de $sign${Fmt.decimal(change)} kg na semana';
  }

  /// Lembrete de que dia sem registro não é dia sem alimentação.
  String? get gapsNote => report.summary.daysLogged < report.daysElapsed
      ? 'Dias sem registro só indicam que nada foi anotado.'
      : null;
}

/// Cartão compacto do Início com acesso ao resumo da semana (Relatórios).
class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = currentWeekQuery();
    final report = ref.watch(periodReportProvider(query));

    return AppCard(
      onTap: () => context.push(AppRoutes.reports),
      semanticLabel: switch (report) {
        AsyncData(:final value) => _semantic(WeeklySummaryText(value)),
        _ => 'Resumo da semana',
      },
      child: switch (report) {
        AsyncData(:final value) => _Body(text: WeeklySummaryText(value)),
        AsyncError(:final error) => _Error(
          message: friendlyMessage(error),
          onRetry: () => ref.invalidate(periodReportProvider(query)),
        ),
        _ => const _Loading(),
      },
    );
  }

  static String _semantic(WeeklySummaryText t) => [
    '${t.title}, ${t.status.toLowerCase()}, ${t.period}.',
    if (t.isEmpty) 'Ainda sem registros nesta semana.' else '${t.daysLogged}.',
    ...t.goals.map((g) => '$g.'),
    if (t.comparison != null) '${t.comparison}.',
    'Toque para ver o resumo completo.',
  ].join(' ');
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.status, this.period});

  final String title;
  final String? status;
  final String? period;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.calendar_view_week_rounded, color: context.colors.primary),
      const SizedBox(width: Space.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleSmall),
            if (period != null) Text(period!, style: context.text.bodySmall),
          ],
        ),
      ),
      if (status != null)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xxs,
          ),
          decoration: BoxDecoration(
            color: status == 'Concluída'
                ? context.pic.successContainer
                : context.pic.surfaceMuted,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(status!, style: context.text.labelSmall),
        ),
      const SizedBox(width: Space.xs),
      const Icon(Icons.chevron_right),
    ],
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.text});

  final WeeklySummaryText text;

  @override
  Widget build(BuildContext context) {
    final secondary = context.text.bodySmall?.copyWith(
      color: context.pic.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: text.title, status: text.status, period: text.period),
        const SizedBox(height: Space.md),
        if (text.isEmpty)
          Text(
            'Seu resumo aparece aqui conforme você registra. Comece por uma refeição ou um copo de água — '
            'em poucos dias você verá sua frequência e suas metas da semana.',
            style: context.text.bodyMedium,
          )
        else ...[
          Text(text.daysLogged, style: context.text.bodyMedium),
          for (final g in text.goals) Text(g, style: context.text.bodyMedium),
          if (text.weight != null)
            Text(text.weight!, style: context.text.bodyMedium),
          if (text.comparison != null) ...[
            const SizedBox(height: Space.xs),
            Text(text.comparison!, style: secondary),
          ],
          if (text.gapsNote != null) ...[
            const SizedBox(height: Space.xs),
            Text(text.gapsNote!, style: secondary),
          ],
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Header(title: 'Resumo da semana'),
      SizedBox(height: Space.md),
      Skeleton(height: 14),
      SizedBox(height: Space.xs),
      Skeleton(height: 14, width: 160),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Header(title: 'Resumo da semana'),
      const SizedBox(height: Space.sm),
      Text(message, style: context.text.bodySmall),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ),
    ],
  );
}
