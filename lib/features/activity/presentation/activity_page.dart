import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../data/activity_models.dart';
import '../data/activity_repository.dart';
import '../domain/activity_math.dart';
import '../domain/activity_visuals.dart';
import 'activity_forms.dart';

/// Tela de atividade física (aberta pelo Início).
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Atividade física')),
    floatingActionButton: FloatingActionButton.extended(
      heroTag: 'activity-log',
      onPressed: () => showActivitySessionForm(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Registrar treino'),
    ),
    body: const ActivityView(),
  );
}

/// Conteúdo da atividade física: semana, metas, eventos e histórico. Usado
/// na tela própria e na aba "Atividade" da Evolução.
class ActivityView extends ConsumerWidget {
  const ActivityView({super.key, this.embedded = false});

  /// Na aba da Evolução não há botão flutuante: o registro fica no topo.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activitySummaryProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(activityEventsProvider)
          ..invalidate(activitySessionsProvider)
          ..invalidate(activityPlansProvider);
        final _ = await ref.refresh(activitySummaryProvider.future);
      },
      child: AsyncValueView<ActivitySummary>(
        value: summary,
        onRetry: () => ref.invalidate(activitySummaryProvider),
        loading: ListView(
          padding: const EdgeInsets.all(Space.page),
          children: const [
            SkeletonCard(lines: 4),
            SizedBox(height: Space.md),
            SkeletonCard(lines: 3),
          ],
        ),
        data: (s) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.md,
            Space.page,
            Space.fabClearance,
          ),
          children: [
            _WeekCard(summary: s),
            if (embedded) ...[
              const SizedBox(height: Space.md),
              FilledButton.icon(
                onPressed: () => showActivitySessionForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar treino'),
              ),
            ],
            const SizedBox(height: Space.section),
            _SectionHeader(
              title: 'Suas metas',
              action: 'Nova meta',
              onAction: () => showActivityPlanForm(context),
            ),
            if (s.plans.isEmpty)
              _EmptyCard(
                icon: Icons.flag_outlined,
                title: 'Defina sua meta da semana',
                message:
                    'Ex.: musculação 3x por semana às 7h, corrida 2x por semana.',
                action: 'Criar meta',
                onAction: () => showActivityPlanForm(context),
              )
            else
              for (final p in s.plans) ...[
                _PlanCard(plan: p),
                const SizedBox(height: Space.sm),
              ],
            const _PausedPlans(),
            const SizedBox(height: Space.section),
            _SectionHeader(
              title: 'Eventos',
              action: 'Adicionar',
              onAction: () => showActivityEventForm(context),
            ),
            const _EventsList(),
            const SizedBox(height: Space.section),
            const _SectionHeader(title: 'Histórico'),
            const _History(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(action!),
          ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: context.pic.brandContainer,
          child: Icon(icon, color: context.pic.onBrandContainer),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.xxs),
              Text(message, style: context.text.bodySmall),
              if (action != null) ...[
                const SizedBox(height: Space.sm),
                FilledButton.tonal(onPressed: onAction, child: Text(action!)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- semana

class _WeekCard extends ConsumerWidget {
  const _WeekCard({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final sessions =
        ref.watch(activitySessionsProvider).value ?? const <ActivitySession>[];
    final activeWeekdays = {
      for (final x in sessions)
        if (!DateUtils.dateOnly(x.performedAt).isBefore(s.weekStart) &&
            !DateUtils.dateOnly(x.performedAt).isAfter(s.weekEnd))
          x.performedAt.weekday,
    };
    final today = DateTime.now().weekday;
    final met = s.sessions >= s.weeklyGoal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: s.weekProgress,
                size: 92,
                strokeWidth: 9,
                semanticLabel:
                    '${s.sessions} de ${s.weeklyGoal} treinos na semana',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${s.sessions}/${s.weeklyGoal}',
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('treinos', style: context.text.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esta semana',
                      style: context.text.labelLarge?.copyWith(
                        color: context.pic.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      met
                          ? 'Meta da semana cumprida!'
                          : s.sessions == 0
                          ? 'Bora começar a semana?'
                          : 'Faltam ${s.weeklyGoal - s.sessions} ${s.weeklyGoal - s.sessions == 1 ? 'treino' : 'treinos'}',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (s.streakWeeks > 0) ...[
                      const SizedBox(height: Space.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 18,
                            color: context.pic.warning,
                          ),
                          const SizedBox(width: Space.xxs),
                          Flexible(
                            child: Text(
                              s.streakWeeks == 1
                                  ? '1 semana com a meta cumprida'
                                  : '${s.streakWeeks} semanas seguidas na meta',
                              style: context.text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          // Dias da semana com atividade.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                _DayDot(
                  label: ActivityVisuals.weekdaysShort[d]!,
                  done: activeWeekdays.contains(d),
                  today: d == today,
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: ActivityMath.duration(s.minutes),
                  label: 'em movimento',
                ),
              ),
              Expanded(
                child: _Stat(
                  value: '${s.activeDays}',
                  label: s.activeDays == 1 ? 'dia ativo' : 'dias ativos',
                ),
              ),
              if (s.distanceKm > 0)
                Expanded(
                  child: _Stat(
                    value: '${Fmt.decimal(s.distanceKm)} km',
                    label: 'percorridos',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.done, required this.today});

  final String label;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: done ? primary : context.pic.surfaceMuted,
            shape: BoxShape.circle,
            border: today ? Border.all(color: primary, width: 2) : null,
          ),
          child: done
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.colors.onPrimary,
                )
              : null,
        ),
        const SizedBox(height: Space.xxs),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            fontWeight: today ? FontWeight.w700 : null,
            color: today ? primary : context.pic.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(label, style: context.text.bodySmall),
    ],
  );
}

// ---------------------------------------------------------------- metas

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final ActivityPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = ActivityVisuals.color(plan.type);
    final next = ActivityMath.nextSlot(plan, DateTime.now());
    return AppCard(
      padding: const EdgeInsets.all(Space.lg),
      onTap: () => showActivityPlanForm(context, plan: plan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ActivityVisuals.icon(plan.type), color: color),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        if (plan.title?.isNotEmpty ?? false) plan.typeLabel,
                        ActivityMath.schedule(plan),
                      ].join(' · '),
                      style: context.text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (plan.reminderEnabled)
                Tooltip(
                  message: 'Lembrete ligado',
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: context.pic.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              for (var i = 0; i < plan.timesPerWeek; i++) ...[
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < plan.doneThisWeek
                          ? color
                          : context.pic.surfaceMuted,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
                if (i < plan.timesPerWeek - 1) const SizedBox(width: Space.xs),
              ],
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.goalMet
                      ? 'Meta cumprida: ${plan.doneThisWeek} de ${plan.timesPerWeek}'
                      : '${plan.doneThisWeek} de ${plan.timesPerWeek} nesta semana'
                            '${next == null ? '' : ' · próximo: ${Fmt.relativeDayTime(next)}'}',
                  style: context.text.bodySmall?.copyWith(
                    color: plan.goalMet ? context.pic.success : null,
                    fontWeight: plan.goalMet ? FontWeight.w600 : null,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => showActivitySessionForm(context, plan: plan),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Treinei'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Metas pausadas, recolhidas no fim da lista.
class _PausedPlans extends ConsumerWidget {
  const _PausedPlans();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = [
      for (final p
          in ref.watch(activityPlansProvider).value ?? const <ActivityPlan>[])
        if (!p.isActive) p,
    ];
    if (paused.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Metas pausadas (${paused.length})',
        style: context.text.titleSmall,
      ),
      children: [
        for (final p in paused)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              ActivityVisuals.icon(p.type),
              color: context.pic.textSecondary,
            ),
            title: Text(p.displayName),
            subtitle: Text(ActivityMath.schedule(p)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showActivityPlanForm(context, plan: p),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- eventos

class _EventsList extends ConsumerWidget {
  const _EventsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activityEventsProvider);
    final now = DateTime.now();
    return switch (events) {
      AsyncData(:final value) => () {
        // Próximos e os da última semana ainda sem participação registrada.
        final visible = [
          for (final e in value)
            if (!e.isPast(now) ||
                (!e.attended && now.difference(e.startsAt).inDays < 7))
              e,
        ];
        if (visible.isEmpty) {
          return _EmptyCard(
            icon: Icons.emoji_events_outlined,
            title: 'Vai participar de algum evento?',
            message:
                'Corrida de rua, passeio de bike, aulão... Adicione para lembrar e acompanhar.',
            action: 'Adicionar evento',
            onAction: () => showActivityEventForm(context),
          );
        }
        return Column(
          children: [
            for (final e in visible) ...[
              _EventCard(event: e, now: now),
              const SizedBox(height: Space.sm),
            ],
          ],
        );
      }(),
      AsyncError() => ErrorView(
        message: 'Não foi possível carregar seus eventos.',
        onRetry: () => ref.invalidate(activityEventsProvider),
      ),
      _ => const SkeletonCard(lines: 2),
    };
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.now});

  final ActivityEvent event;
  final DateTime now;

  static const _months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  String _countdown() {
    final days = DateUtils.dateOnly(
      event.startsAt,
    ).difference(DateUtils.dateOnly(now)).inDays;
    if (event.isPast(now)) return 'Já aconteceu';
    if (days == 0) return 'Hoje, ${Fmt.time(event.startsAt)}';
    if (days == 1) return 'Amanhã, ${Fmt.time(event.startsAt)}';
    return 'Em $days dias · ${Fmt.time(event.startsAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = ActivityVisuals.color(event.type);
    final past = event.isPast(now);
    return AppCard(
      padding: const EdgeInsets.all(Space.lg),
      onTap: () => showActivityEventForm(context, event: event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '${event.startsAt.day}',
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      _months[event.startsAt.month - 1],
                      style: context.text.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      [
                        event.typeLabel,
                        if (event.distanceKm != null)
                          '${Fmt.decimal(event.distanceKm!)} km',
                        if (event.location != null) event.location!,
                      ].join(' · '),
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: past ? context.pic.textSecondary : color,
                        ),
                        const SizedBox(width: Space.xxs),
                        Text(
                          _countdown(),
                          style: context.text.labelMedium?.copyWith(
                            color: past ? context.pic.textSecondary : color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (past || event.url != null) ...[
            const SizedBox(height: Space.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (event.url != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(event.url!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Abrir link'),
                  ),
                if (past && !event.attended)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        showActivitySessionForm(context, event: event),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Participei'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- histórico

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(activitySessionsProvider);
    final options = ref.watch(activityOptionsProvider).value;
    final weight = ref.watch(currentAccountProvider)?.profile.currentWeightKg;
    return switch (sessions) {
      AsyncData(:final value) when value.isEmpty => const _EmptyCard(
        icon: Icons.history_rounded,
        title: 'Nenhum treino registrado ainda',
        message: 'Seus treinos dos últimos 60 dias aparecem aqui.',
      ),
      AsyncData(:final value) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Column(
          children: [
            for (final (i, s) in value.take(30).indexed) ...[
              if (i > 0) const Divider(height: 1, indent: 72),
              _SessionTile(
                session: s,
                kcal: ActivityMath.estimatedKcal(
                  type: options?.type(s.type),
                  durationMin: s.durationMin,
                  weightKg: weight,
                  intensity: options?.intensity(s.intensity),
                ),
              ),
            ],
          ],
        ),
      ),
      AsyncError() => ErrorView(
        message: 'Não foi possível carregar o histórico.',
        onRetry: () => ref.invalidate(activitySessionsProvider),
      ),
      _ => const SkeletonCard(lines: 3),
    };
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.kcal});

  final ActivitySession session;
  final int? kcal;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final color = ActivityVisuals.color(s.type);
    final pace = ActivityMath.pace(s.durationMin, s.distanceKm);
    return ListTile(
      onTap: () => showActivitySessionForm(context, session: s),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(ActivityVisuals.icon(s.type), color: color),
      ),
      title: Text(s.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          Fmt.relativeDayTime(s.performedAt),
          ActivityMath.duration(s.durationMin),
          if (s.distanceKm != null) '${Fmt.decimal(s.distanceKm!)} km',
          ?pace,
        ].join(' · '),
      ),
      trailing: kcal == null
          ? null
          : Text(
              '~${Fmt.integer(kcal!)} kcal',
              style: context.text.labelMedium,
            ),
    );
  }
}
