import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../data/activity_models.dart';
import '../data/activity_repository.dart';
import '../domain/activity_math.dart';
import '../domain/activity_visuals.dart';
import 'activity_forms.dart';

/// Atividade física no Início: treinos da semana contra a meta, o
/// andamento de cada meta, o próximo evento e o botão de registrar.
class ActivityHomeCard extends ConsumerWidget {
  const ActivityHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activitySummaryProvider);
    return switch (summary) {
      AsyncData(:final value) => _Content(summary: value),
      // Sem os dados de atividade, o Início segue com o restante.
      AsyncError() => const SizedBox.shrink(),
      _ => const SkeletonCard(lines: 2),
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final pic = context.pic;
    final event = s.upcomingEvents
        .where((e) => !e.isPast(DateTime.now()))
        .firstOrNull;
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: pic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.activity),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_run_rounded,
                    size: 20,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Atividade física',
                        style: context.text.labelLarge?.copyWith(
                          color: pic.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (s.streakWeeks > 1) ...[
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: pic.warning,
                    ),
                    const SizedBox(width: Space.xxs),
                    Text(
                      '${s.streakWeeks} semanas',
                      style: context.text.labelMedium,
                    ),
                    const SizedBox(width: Space.xs),
                  ],
                  Icon(Icons.chevron_right_rounded, color: pic.textSecondary),
                ],
              ),
              const SizedBox(height: Space.md),
              if (s.plans.isEmpty && s.sessions == 0) ...[
                Text(
                  'Defina sua meta da semana',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Academia, corrida, caminhada... Escolha quantas vezes por semana e o horário.',
                  style: context.text.bodyMedium?.copyWith(
                    color: pic.textSecondary,
                  ),
                ),
                const SizedBox(height: Space.md),
                FilledButton.tonalIcon(
                  onPressed: () => showActivityPlanForm(context),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Criar meta'),
                ),
              ] else ...[
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${s.sessions}',
                        style: context.text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${s.weeklyGoal} treinos na semana',
                        style: context.text.titleSmall?.copyWith(
                          color: pic.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: s.weekProgress,
                    minHeight: 8,
                    color: context.colors.primary,
                    backgroundColor: pic.surfaceMuted,
                  ),
                ),
                if (s.plans.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final p in s.plans.take(4)) _PlanChip(plan: p),
                    ],
                  ),
                ],
                if (s.minutes > 0) ...[
                  const SizedBox(height: Space.sm),
                  Text(
                    '${ActivityMath.duration(s.minutes)} em movimento nesta semana',
                    style: context.text.bodySmall,
                  ),
                ],
              ],
              if (event != null) ...[
                const SizedBox(height: Space.md),
                _NextEvent(event: event),
              ],
              if (s.plans.isNotEmpty || s.sessions > 0) ...[
                const SizedBox(height: Space.md),
                FilledButton.tonalIcon(
                  onPressed: () => showActivitySessionForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar treino'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.plan});

  final ActivityPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = ActivityVisuals.color(plan.type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            plan.goalMet
                ? Icons.check_circle_rounded
                : ActivityVisuals.icon(plan.type),
            size: 16,
            color: color,
          ),
          const SizedBox(width: Space.xs),
          Text(
            '${plan.displayName} ${plan.doneThisWeek}/${plan.timesPerWeek}',
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextEvent extends StatelessWidget {
  const _NextEvent({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.dateOnly(
      event.startsAt,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final when = days == 0
        ? 'hoje'
        : days == 1
        ? 'amanhã'
        : 'em $days dias';
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: context.pic.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: ActivityVisuals.color(event.type),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              '${event.name} · $when',
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
