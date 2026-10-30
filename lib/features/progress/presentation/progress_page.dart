import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/features.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/progress_widgets.dart';
import '../../../shared/widgets/state_views.dart';
import '../../activity/presentation/activity_page.dart';
import '../../auth/application/session_controller.dart';
import '../../engagement/data/engagement_repository.dart';
import '../../engagement/presentation/engagement_widgets.dart';
import '../../medication/presentation/medication_tab.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/weekly_summary_card.dart';
import '../data/body_models.dart';
import '../data/body_repository.dart';
import 'body_forms.dart';
import 'progress_photos.dart';

/// Evolução: um resumo (sequência, semana, relatórios, hábitos e bem-estar),
/// peso, medidas, fotos e, quando ativado, o medicamento.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A aba de medicamento só aparece para quem ativou o acompanhamento; o
    // convite para ativar fica no Perfil.
    final medication =
        AppFeatures.medical &&
        (ref.watch(currentAccountProvider)?.profile.medicationTrackingEnabled ??
            false);
    final tabs = [
      const Tab(text: 'Resumo'),
      const Tab(text: 'Atividade'),
      const Tab(text: 'Peso'),
      const Tab(text: 'Medidas'),
      const Tab(text: 'Fotos'),
      if (medication) const Tab(text: 'Medicamento'),
    ];

    return DefaultTabController(
      // A chave recria o controlador quando a aba de medicamento entra ou sai.
      key: ValueKey(tabs.length),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          actions: const [NotificationBell()],
          title: const Text('Evolução'),
          bottom: TabBar(
            tabs: tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
          ),
        ),
        body: TabBarView(
          children: [
            const _SummaryTab(),
            const ActivityView(embedded: true),
            const _WeightTab(),
            const _MeasurementsTab(),
            const ProgressPhotosTab(),
            if (medication) const MedicationTab(),
          ],
        ),
      ),
    );
  }
}

/// Visão geral da Evolução: constância, semana e o caminho para relatórios,
/// hábitos e bem-estar, cada um com rótulo visível.
class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      ref
        ..invalidate(engagementProvider)
        ..invalidate(periodReportProvider);
    },
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Space.page),
      children: [
        const StreakCard(),
        const SizedBox(height: Space.md),
        const WeeklySummaryCard(),
        const SizedBox(height: Space.section),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded),
                title: const Text('Relatórios'),
                subtitle: const Text('Semana, mês e exportação'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.reports),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Hábitos e conquistas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.engagement),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.spa_outlined),
                title: const Text('Bem-estar'),
                subtitle: const Text('Sintomas, linha do tempo e resumo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.symptoms),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeightTab extends ConsumerStatefulWidget {
  const _WeightTab();

  @override
  ConsumerState<_WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<_WeightTab> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(bodyProgressProvider(_days));
    final entries = ref.watch(weightEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-weight',
        onPressed: () => showWeightForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Peso'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(bodyProgressProvider(_days))
            ..invalidate(weightEntriesProvider);
          await ref.read(bodyProgressProvider(_days).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final (days, label) in const [
                  (7, '7 dias'),
                  (30, '30 dias'),
                  (90, '3 meses'),
                  (180, '6 meses'),
                  (365, '1 ano'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _days == days,
                    onSelected: (_) => setState(() => _days = days),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncValueView<BodyProgress>(
              value: progress,
              onRetry: () => ref.invalidate(bodyProgressProvider(_days)),
              data: (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Tendência, em uma frase.
                  _TrendCard(trend: p.trend),
                  const SizedBox(height: Space.lg),
                  // 2. Gráfico com uma explicação curta ao lado.
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stat(
                          value: signedKg(p.changeKg),
                          label: 'variação no período',
                        ),
                        const SizedBox(height: Space.lg),
                        if (p.series.length >= 2)
                          DateLineChart(
                            points: [
                              for (final s in p.series) (s.date, s.weightKg),
                            ],
                            unit: 'kg',
                            target: p.goal?.goalWeightKg,
                            markers: [
                              if (AppFeatures.medical)
                                for (final d in p.doses) d.date,
                            ],
                          )
                        else
                          const Text(
                            'Registre o peso em pelo menos dois dias diferentes do período para ver o gráfico.',
                          ),
                        if (p.series.length >= 2) ...[
                          const SizedBox(height: Space.sm),
                          Text(
                            p.goal != null
                                ? 'Cada ponto é um registro de peso. A linha horizontal é o seu objetivo.'
                                : 'Cada ponto é um registro de peso. Olhe a direção da linha, não um dia isolado.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (AppFeatures.medical &&
                            p.series.length >= 2 &&
                            p.doses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Linhas tracejadas roxas: aplicações registradas (${p.doses.length} no período). '
                            'Proximidade no tempo não indica causa.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 3. Indicadores secundários, recolhidos.
                  const SizedBox(height: Space.lg),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Mais indicadores',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: const Text(
                      'Último peso, período anterior, objetivo e IMC',
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Stat(
                              value: p.series.isEmpty
                                  ? '—'
                                  : Fmt.kg(p.series.last.weightKg),
                              label: 'último no período',
                            ),
                          ),
                          Expanded(
                            child: Stat(
                              value: signedKg(p.previousChangeKg),
                              label: 'período anterior',
                            ),
                          ),
                        ],
                      ),
                      if (p.goal != null) ...[
                        const SizedBox(height: Space.md),
                        SectionCard(
                          title: 'Objetivo pessoal',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LabeledProgress(
                                label:
                                    'De ${Fmt.kg(p.goal!.startWeightKg)} para ${Fmt.kg(p.goal!.goalWeightKg)}',
                                value: p.goal!.progressPercent,
                                unit: '%',
                                goal: 100,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mudanças graduais e sustentáveis tendem a ser mais saudáveis. '
                                'Converse com um profissional de saúde sobre o ritmo adequado para você.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: Space.md),
                      SectionCard(
                        title: 'IMC',
                        child: p.bmi.available
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stat(
                                    value: Fmt.decimal(p.bmi.value!),
                                    label: p.bmi.category ?? '',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.bmi.note,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              )
                            : Text(
                                p.bmi.reason == 'missing_data'
                                    ? 'Informe sua altura no perfil e registre o peso para calcular o IMC.'
                                    : p.bmi.note,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.section),
            Text('Histórico', style: theme.textTheme.titleMedium),
            entries.when(
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nenhum registro de peso ainda.'),
                    )
                  : Column(
                      children: [
                        for (final e in list.take(60))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(Fmt.kg(e.weightKg)),
                            subtitle: Text(Fmt.shortDate(e.measuredAt)),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => showWeightForm(context, entry: e),
                          ),
                      ],
                    ),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: friendlyMessage(e),
                onRetry: () => ref.invalidate(weightEntriesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementsTab extends ConsumerWidget {
  const _MeasurementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(measurementsProvider);
    final progress = ref.watch(bodyProgressProvider(90));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-measurement',
        onPressed: () => showMeasurementForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Medida'),
      ),
      body: AsyncValueView<List<Measurement>>(
        value: measurements,
        onRetry: () => ref.invalidate(measurementsProvider),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.straighten,
                title: 'Nenhuma medida registrada',
                message:
                    'Medidas como cintura e quadril ajudam a acompanhar mudanças que a balança não mostra.',
                actionLabel: 'Registrar medida',
                onAction: () => showMeasurementForm(context),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  ...progress.maybeWhen(
                    data: (p) => [
                      if (p.measurements.isNotEmpty)
                        SectionCard(
                          title: 'Últimos 3 meses',
                          child: Column(
                            children: [
                              for (final m in p.measurements)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    MeasurementTypes.label(m.type, m.label),
                                  ),
                                  subtitle: Text(
                                    'Atual: ${Fmt.decimal(m.lastCm)} cm',
                                  ),
                                  trailing: Text(
                                    m.changeCm == null
                                        ? '—'
                                        : '${m.changeCm! > 0 ? '+' : ''}${Fmt.decimal(m.changeCm!)} cm',
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    orElse: () => const <Widget>[],
                  ),
                  const SizedBox(height: 12),
                  for (final m in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${m.displayName}: ${Fmt.decimal(m.valueCm)} cm',
                      ),
                      subtitle: Text(Fmt.shortDate(m.measuredAt)),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => showMeasurementForm(context, entry: m),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Ritmo das últimas semanas, com a ressalva de que não é promessa.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final WeightTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!trend.available) {
      return SectionCard(
        title: 'Tendência',
        icon: Icons.trending_flat,
        child: Text(
          trend.message ??
              'Registre o peso por algumas semanas para ver a tendência.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final weekly = trend.weeklyChangeKg ?? 0;
    final rate = switch (trend.direction) {
      'stable' => 'Peso estável nas últimas 4 semanas',
      _ =>
        '${weekly > 0 ? '+' : ''}${Fmt.decimal(weekly)} kg por semana nas últimas 4 semanas',
    };
    return SectionCard(
      title: 'Tendência',
      icon: switch (trend.direction) {
        'down' => Icons.trending_down,
        'up' => Icons.trending_up,
        _ => Icons.trending_flat,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rate, style: theme.textTheme.titleSmall),
          if (trend.goalDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Se esse ritmo continuar, você chegaria a ${Fmt.kg(trend.goalWeightKg ?? 0)} '
              'por volta de ${Fmt.shortDate(trend.goalDate!)} (cerca de ${trend.goalWeeks} semanas).',
            ),
          ],
          if (trend.fastChange && trend.fastChangeNote != null) ...[
            const SizedBox(height: 8),
            StatusBanner(
              tone: BannerTone.warning,
              message: trend.fastChangeNote!,
            ),
          ],
          const SizedBox(height: 8),
          Text(trend.note ?? '', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
