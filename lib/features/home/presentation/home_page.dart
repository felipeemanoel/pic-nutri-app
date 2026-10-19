import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/progress_widgets.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../engagement/data/engagement_repository.dart';
import '../../engagement/presentation/engagement_widgets.dart';
import '../../profile/data/profile_repository.dart';
import '../../progress/presentation/body_forms.dart';
import '../../water/data/water_repository.dart';
import '../data/dashboard.dart';
import '../data/dashboard_repository.dart';

/// Painel do dia com os dados reais do usuário, organizado por importância:
/// resumo do dia, ações rápidas, água, evolução e lembretes.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final dashboard = ref.watch(dashboardProvider(day));
    final name = ref.watch(currentAccountProvider)?.firstName ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () {
            ref.invalidate(engagementProvider);
            return ref.refresh(dashboardProvider(day).future);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.lg,
                  Space.page,
                  Space.xxl,
                ),
                children: [
                  _Header(name: name),
                  const SizedBox(height: Space.xxl),
                  const DayNavigator(),
                  const SizedBox(height: Space.xl),
                  AsyncValueView<Dashboard>(
                    value: dashboard,
                    onRetry: () => ref.invalidate(dashboardProvider(day)),
                    loading: const _DashboardSkeleton(),
                    data: (data) => _DashboardBody(data: data),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                name.isEmpty ? _greeting : '$_greeting, $name',
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              _capitalize(Fmt.fullDate(DateTime.now())),
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Lembretes',
        icon: const Icon(Icons.notifications_none_rounded),
        onPressed: () => context.push(AppRoutes.reminders),
      ),
      const ProfileButton(),
    ],
  );
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _JourneyBanner extends StatelessWidget {
  const _JourneyBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.xxl),
    decoration: BoxDecoration(
      borderRadius: Radii.card,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.colors.primaryContainer, context.colors.surface],
      ),
      border: Border.all(color: context.pic.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEU ESPAÇO DE CUIDADO',
                style: context.text.labelSmall?.copyWith(
                  color: context.pic.onBrandContainer,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text('Cada cuidado conta.', style: context.text.headlineSmall),
              const SizedBox(height: Space.sm),
              Text(
                'Sua evolução, no seu ritmo.\nUm dia de cada vez.',
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: Space.md),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.spa_outlined,
            size: 32,
            color: context.colors.primary,
          ),
        ),
      ],
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SkeletonCard(lines: 4),
      SizedBox(height: Space.md),
      SkeletonCard(lines: 2),
      SizedBox(height: Space.md),
      SkeletonCard(lines: 2),
    ],
  );
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _CompleteProfileCard(),
      const _JourneyBanner(),
      const SizedBox(height: Space.xl),
      _DaySummaryCard(data: data),
      const SizedBox(height: Space.lg),
      Text('Registrar no seu dia', style: context.text.titleMedium),
      const SizedBox(height: Space.sm),
      _QuickActions(isToday: data.isToday),
      const SizedBox(height: Space.lg),
      if (data.isToday) ...[
        const StreakCard(),
        const SizedBox(height: Space.md),
      ],
      Text('Seu acompanhamento', style: context.text.titleMedium),
      const SizedBox(height: Space.md),
      _WaterCard(data: data),
      const SizedBox(height: Space.md),
      _WeightCard(data: data),
      if (data.medicationTrackingEnabled) ...[
        const SizedBox(height: Space.md),
        _MedicationCard(data: data),
      ],
      const SizedBox(height: Space.md),
      AppCard(
        onTap: () => context.go(AppRoutes.reports),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: context.colors.primary),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo semanal e mensal',
                    style: context.text.titleSmall,
                  ),
                  Text(
                    'Médias, metas atingidas e comparações',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      const SizedBox(height: Space.md),
      _RemindersCard(data: data),
    ],
  );
}

/// Destaque do dia: calorias em relação à meta do usuário, refeições e macros.
class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    final goal = n.goalKcal;
    final hasGoal = goal != null && goal > 0;

    if (n.mealsCount == 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do dia', style: context.text.titleMedium),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.pic.brandContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: Space.md),
                const Expanded(
                  child: Text('Nenhuma refeição registrada neste dia.'),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(
              'Registre o que comeu, por foto ou manualmente, para acompanhar calorias e macronutrientes.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.food),
              icon: const Icon(Icons.add),
              label: const Text('Registrar refeição'),
            ),
            if (data.pendingMeals.isNotEmpty && data.isToday) ...[
              const SizedBox(height: Space.md),
              _PendingMeals(meals: data.pendingMeals),
            ],
          ],
        ),
      );
    }

    final remaining = n.remainingKcal;
    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      onTap: () => context.go(AppRoutes.food),
      semanticLabel: 'Resumo do dia. Toque para abrir o diário alimentar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Resumo do dia', style: context.text.titleMedium),
              ),
              Text(
                '${n.mealsCount} ${n.mealsCount == 1 ? 'refeição' : 'refeições'}',
                style: context.text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              ProgressRing(
                progress: hasGoal ? n.totals.energyKcal / goal : null,
                size: 124,
                semanticLabel: hasGoal
                    ? '${Fmt.kcal(n.totals.energyKcal)} de ${Fmt.kcal(goal)}'
                    : '${Fmt.kcal(n.totals.energyKcal)} registradas',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Fmt.integer(n.totals.energyKcal),
                      style: context.text.headlineSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text('kcal', style: context.text.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: Space.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registradas', style: context.text.labelSmall),
                    Text(
                      Fmt.kcal(n.totals.energyKcal),
                      style: context.text.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    if (hasGoal && remaining != null) ...[
                      Text(
                        remaining >= 0 ? 'Restantes da meta' : 'Acima da meta',
                        style: context.text.labelSmall,
                      ),
                      Text(
                        Fmt.kcal(remaining.abs()),
                        style: context.text.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ] else
                      Text(
                        'Defina uma meta de calorias no perfil para acompanhar o progresso.',
                        style: context.text.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          MacroSummary(
            proteinG: n.totals.proteinG,
            carbsG: n.totals.carbsG,
            fatG: n.totals.fatG,
            proteinGoal: n.goalProteinG,
            carbsGoal: n.goalCarbsG,
            fatGoal: n.goalFatG,
          ),
          if (data.pendingMeals.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            _PendingMeals(meals: data.pendingMeals),
          ],
        ],
      ),
    );
  }
}

/// Refeições habituais ainda sem registro no dia (toque abre o registro).
class _PendingMeals extends StatelessWidget {
  const _PendingMeals({required this.meals});

  final List<PendingMeal> meals;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ainda sem registro', style: context.text.labelSmall),
      const SizedBox(height: Space.xs),
      Wrap(
        spacing: Space.sm,
        runSpacing: Space.xs,
        children: [
          for (final m in meals)
            ActionChip(
              avatar: Icon(m.late ? Icons.schedule : Icons.add, size: 16),
              label: Text(m.label),
              tooltip: m.late
                  ? '${m.label}: horário habitual já passou'
                  : 'Registrar ${m.label}',
              onPressed: () => context.go(AppRoutes.food),
            ),
        ],
      ),
    ],
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: QuickAction(
          icon: Icons.add_rounded,
          label: 'Refeição',
          onTap: () => context.go(AppRoutes.newMeal),
        ),
      ),
      Expanded(
        child: QuickAction(
          icon: Icons.photo_camera_outlined,
          label: 'Foto do prato',
          ai: true,
          onTap: () => context.go(AppRoutes.mealPhoto),
        ),
      ),
      Expanded(
        child: QuickAction(
          icon: Icons.water_drop_outlined,
          label: 'Água',
          onTap: () => context.push(AppRoutes.water),
        ),
      ),
      Expanded(
        child: QuickAction(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso',
          onTap: () => showWeightForm(context),
        ),
      ),
      Expanded(
        child: QuickAction(
          icon: Icons.healing_outlined,
          label: 'Sintoma',
          onTap: () => context.push(AppRoutes.symptoms),
        ),
      ),
    ],
  );
}

class _WaterCard extends ConsumerStatefulWidget {
  const _WaterCard({required this.data});

  final Dashboard data;

  @override
  ConsumerState<_WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends ConsumerState<_WaterCard> {
  bool _saving = false;

  Future<void> _add(int ml) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(waterRepositoryProvider)
          .add(
            ml,
            requestId: newRequestId(),
            at: widget.data.isToday
                ? null
                : widget.data.date.add(const Duration(hours: 12)),
          );
      Refresh.water(ref);
      if (mounted) showMessage(context, '+$ml ml registrados.');
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final water = context.pic.water;
    return AppCard(
      onTap: () => context.push(AppRoutes.water),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 20, color: water),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Hidratação', style: context.text.titleMedium),
              ),
              Text(
                '${Fmt.ml(d.waterTotalMl)} / ${Fmt.ml(d.waterGoalMl)}',
                style: context.text.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ProgressBar(
            progress: d.waterGoalMl > 0 ? d.waterTotalMl / d.waterGoalMl : 0,
            color: water,
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final ml in const [200, 300, 500])
                ActionChip(
                  avatar: Icon(Icons.add, size: 18, color: water),
                  label: Text('$ml ml'),
                  tooltip: 'Adicionar $ml ml',
                  onPressed: _saving ? null : () => _add(ml),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final w = data.weight;
    final goal = data.goal;
    return SectionCard(
      title: 'Evolução',
      icon: Icons.insights_outlined,
      onTap: () => context.go(AppRoutes.progress),
      child: w == null
          ? Row(
              children: [
                const Expanded(
                  child: Text(
                    'Registre seu peso na aba Evolução para acompanhar seu progresso.',
                  ),
                ),
                TextButton(
                  onPressed: () => showWeightForm(context),
                  child: const Text('Registrar'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stat(
                        value: Fmt.kg(w.latestKg),
                        label: 'em ${Fmt.dayMonth(w.latestDate)}',
                      ),
                    ),
                    Expanded(
                      child: Stat(
                        value: signedKg(w.change30dKg),
                        label: 'nos últimos 30 dias',
                      ),
                    ),
                  ],
                ),
                if (w.series.length >= 2) ...[
                  const SizedBox(height: Space.md),
                  Sparkline(
                    points: [for (final p in w.series) (p.date, p.weightKg)],
                    semanticLabel:
                        'Peso de ${Fmt.kg(w.series.first.weightKg)} a ${Fmt.kg(w.series.last.weightKg)} nos últimos 30 dias',
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      'Com mais registros, a linha de evolução aparece aqui.',
                      style: context.text.bodySmall,
                    ),
                  ),
                if (goal != null) ...[
                  const SizedBox(height: Space.md),
                  LabeledProgress(
                    label: 'Caminho até ${Fmt.kg(goal.goalWeightKg)}',
                    value: goal.progressPercent,
                    unit: '%',
                    goal: 100,
                  ),
                ],
              ],
            ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final last = data.lastDose;
    return AppCard(
      color: context.pic.aiContainer,
      borderColor: context.pic.ai.withValues(alpha: 0.18),
      onTap: () => context.go(AppRoutes.progress),
      child: Row(
        children: [
          Icon(Icons.medication_outlined, color: context.colors.primary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last == null
                      ? 'Nenhuma aplicação registrada'
                      : 'Última aplicação: ${last.medicationName}',
                  style: context.text.titleSmall,
                ),
                Text(
                  last == null
                      ? 'Registre aplicações e sintomas em Evolução.'
                      : '${Fmt.shortDate(last.takenAt)} às ${Fmt.time(last.takenAt)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Próximos lembretes',
    icon: Icons.alarm_outlined,
    onTap: () => context.push(AppRoutes.reminders),
    child: data.nextReminders.isEmpty
        ? Text(
            'Configure lembretes de água, refeições e pesagem.',
            style: context.text.bodySmall,
          )
        : Column(
            children: [
              for (final r in data.nextReminders)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          Fmt.time(r.at),
                          style: context.text.titleSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _sameDay(r.at, DateTime.now())
                            ? 'Hoje'
                            : Fmt.dayMonth(r.at),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Etapas do onboarding puladas: lembra de completar (ou dispensar).
class _CompleteProfileCard extends ConsumerWidget {
  const _CompleteProfileCard();

  static const _labels = {
    'essentials': 'dados básicos',
    'routine': 'alimentação e rotina',
    'guidance': 'orientação profissional',
    'medication': 'medicamento',
    'care': 'preferências de atendimento',
    'targets': 'metas diárias',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipped =
        (ref.watch(currentAccountProvider)?.onboardingSkipped ??
                const <String>[])
            .where(_labels.containsKey)
            .toList();
    if (skipped.isEmpty) return const SizedBox.shrink();

    Future<void> dismiss() async {
      try {
        final account = await ref
            .read(profileRepositoryProvider)
            .saveOnboardingProgress(step: 'summary', skipped: const []);
        ref.read(sessionControllerProvider.notifier).updateAccount(account);
      } on Object catch (e) {
        if (context.mounted) showFailure(context, e);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: StatusBanner(
        title: 'Complete seu perfil',
        message:
            'Ficou para depois: ${skipped.map((s) => _labels[s]).join(', ')}. Com esses dados, metas e sugestões ficam mais precisas.',
        actionLabel: 'Completar agora',
        onAction: () async {
          await context.push(AppRoutes.editProfile);
          if (context.mounted) await dismiss();
        },
      ),
    );
  }
}
