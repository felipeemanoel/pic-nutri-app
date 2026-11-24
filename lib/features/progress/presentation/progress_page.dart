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
import 'progress_photo_highlight.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
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
      padding: const EdgeInsets.fromLTRB(
        Space.page,
        Space.lg,
        Space.page,
        Space.xxxl,
      ),
      children: [
        const _WeightHero(),
        const SizedBox(height: Space.md),
        const WeeklySummaryCard(),
        const SizedBox(height: Space.md),
        const StreakCard(),
        const SizedBox(height: Space.md),
        const ProgressPhotoHighlight(),
        const SectionHeader(title: 'Mais sobre você'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              _LinkTile(
                icon: Icons.bar_chart_rounded,
                title: 'Relatórios',
                subtitle: 'Semana, mês e exportação',
                onTap: () => context.push(AppRoutes.reports),
              ),
              const Divider(height: 1, indent: 72),
              _LinkTile(
                icon: Icons.emoji_events_outlined,
                title: 'Hábitos e conquistas',
                subtitle: 'Sequência, níveis e metas do dia',
                onTap: () => context.push(AppRoutes.engagement),
              ),
              const Divider(height: 1, indent: 72),
              _LinkTile(
                icon: Icons.spa_outlined,
                title: 'Bem-estar',
                subtitle: 'Sintomas, linha do tempo e resumo',
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
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.md,
            Space.page,
            Space.fabClearance,
          ),
          children: [
            Wrap(
              spacing: Space.sm,
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
            const SizedBox(height: Space.md),
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
            const SectionHeader(title: 'Histórico'),
            entries.when(
              data: (list) => list.isEmpty
                  ? Text(
                      'Nenhum registro de peso ainda.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.pic.textSecondary,
                      ),
                    )
                  : _HistoryCard(
                      children: [
                        for (final e in list.take(60))
                          _HistoryRow(
                            value: Fmt.kg(e.weightKg),
                            date: Fmt.shortDate(e.measuredAt),
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
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.md,
                  Space.page,
                  Space.fabClearance,
                ),
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
                                        : '${m.changeCm! > 0 ? '+' : (m.changeCm! < 0 ? '−' : '')}${Fmt.decimal(m.changeCm!.abs())} cm',
                                    style: context.text.titleSmall?.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    orElse: () => const <Widget>[],
                  ),
                  const SectionHeader(title: 'Histórico'),
                  _HistoryCard(
                    children: [
                      for (final m in list)
                        _HistoryRow(
                          value:
                              '${m.displayName}: ${Fmt.decimal(m.valueCm)} cm',
                          date: Fmt.shortDate(m.measuredAt),
                          onTap: () => showMeasurementForm(context, entry: m),
                        ),
                    ],
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

/// Destaque da Evolução: peso atual, variação em 30 dias (neutra, sem
/// julgamento) e o caminho até o objetivo. Único cartão em cor sólida da
/// tela, como o resumo do dia no Início e na Alimentação.
class _WeightHero extends ConsumerWidget {
  const _WeightHero();

  static const _days = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pic;
    final progress = ref.watch(bodyProgressProvider(_days));
    final muted = context.text.bodyMedium?.copyWith(color: p.onHeroMuted);
    return AppCard(
      color: p.heroSurface,
      borderColor: Colors.transparent,
      // Toque leva à aba Peso, com gráfico e histórico.
      onTap: () => DefaultTabController.of(context).animateTo(2),
      child: switch (progress) {
        AsyncData(:final value) => _body(context, value),
        AsyncError() => Row(
          children: [
            Expanded(
              child: Text('Não foi possível carregar seu peso.', style: muted),
            ),
            TextButton(
              onPressed: () => ref.invalidate(bodyProgressProvider(_days)),
              style: TextButton.styleFrom(foregroundColor: p.onHero),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
        _ => const SizedBox(height: 120),
      },
    );
  }

  Widget _body(BuildContext context, BodyProgress b) {
    final p = context.pic;
    final t = context.text;
    final muted = t.bodyMedium?.copyWith(color: p.onHeroMuted);
    final latest = b.series.isEmpty ? null : b.series.last.weightKg;
    if (latest == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seu peso', style: t.titleMedium?.copyWith(color: p.onHero)),
          const SizedBox(height: Space.xs),
          Text(
            'Registre seu peso para acompanhar a evolução aqui.',
            style: muted,
          ),
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: () => showWeightForm(context),
            style: FilledButton.styleFrom(
              backgroundColor: p.onHero,
              foregroundColor: p.heroSurface,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Registrar peso'),
          ),
        ],
      );
    }
    final goal = b.goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Peso atual',
                style: t.labelMedium?.copyWith(color: p.onHeroMuted),
              ),
            ),
            Text(
              'Últimos $_days dias',
              style: t.labelMedium?.copyWith(color: p.onHeroMuted),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MetricValue(
              value: Fmt.decimal(latest),
              unit: 'kg',
              large: true,
              color: p.onHero,
              unitColor: p.onHeroMuted,
            ),
            // Variação em cor neutra, com sinal: nem "boa" nem "ruim".
            if (b.changeKg != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.xs,
                ),
                decoration: BoxDecoration(
                  color: p.heroTrack,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  '${signedKg(b.changeKg)} no período',
                  style: t.labelMedium?.copyWith(
                    color: p.onHero,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        if (b.series.length >= 2) ...[
          const SizedBox(height: Space.md),
          Sparkline(
            points: [for (final s in b.series) (s.date, s.weightKg)],
            color: p.onHero,
            semanticLabel: 'Peso nos últimos $_days dias',
          ),
        ],
        if (goal != null) ...[
          Divider(color: p.heroTrack, height: Space.xxxl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Objetivo: ${Fmt.kg(goal.goalWeightKg)}',
                  style: muted,
                ),
              ),
              Text(
                '${Fmt.integer(goal.progressPercent)}%',
                style: t.labelLarge?.copyWith(
                  color: p.onHero,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ProgressBar(
            progress: (goal.progressPercent / 100).clamp(0.0, 1.0),
            color: p.onHero,
            trackColor: p.heroTrack,
            height: 6,
          ),
        ],
      ],
    );
  }
}

/// Atalho em lista: ícone da marca, título, descrição e seta.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: IconBadge(icon: icon),
    title: Text(title, style: context.text.titleSmall),
    subtitle: Text(subtitle, style: context.text.bodySmall),
    trailing: Icon(Icons.chevron_right, color: context.pic.textSecondary),
    onTap: onTap,
  );
}

/// Histórico de registros (peso, medidas) num cartão com divisórias.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: Space.lg),
          children[i],
        ],
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.value,
    required this.date,
    required this.onTap,
  });

  final String value;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      value,
      style: context.text.titleSmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    subtitle: Text(date, style: context.text.bodySmall),
    trailing: Icon(
      Icons.edit_outlined,
      size: 20,
      color: context.pic.textSecondary,
    ),
    onTap: onTap,
  );
}
