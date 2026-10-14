import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';

/// Segunda-feira da semana de [day].
DateTime mondayOf(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

String weekRange(DateTime start, DateTime end) =>
    '${Fmt.dayMonth(start)} – ${Fmt.dayMonth(end)}';

/// Planos semanais do usuário: criar, reaproveitar e abrir.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(mealPlansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano alimentar'),
        actions: [
          IconButton(
            tooltip: 'Receitas',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push(AppRoutes.recipes),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createPlanFlow(context, ref, plans.value ?? const []),
        icon: const Icon(Icons.add),
        label: const Text('Novo plano'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mealPlansProvider.future),
        child: AsyncValueView<List<MealPlanSummary>>(
          value: plans,
          onRetry: () => ref.invalidate(mealPlansProvider),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: Space.xxxl),
                    EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'Planeje sua semana',
                      message:
                          'Organize refeições com receitas e alimentos do banco, veja os totais de cada dia e gere a lista de compras.',
                      actionLabel: 'Planejar esta semana',
                      onAction: () => createPlanFlow(context, ref, list),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.fabClearance),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (context, i) => _PlanCard(plan: list[i], all: list),
                ),
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.all});

  final MealPlanSummary plan;
  final List<MealPlanSummary> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = plan.contains(DateTime.now());
    return AppCard(
      onTap: () => context.push(AppRoutes.mealPlan(plan.id)),
      borderColor: current ? context.colors.primary : null,
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: context.colors.primary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title, style: context.text.titleSmall),
                Text(
                  '${weekRange(plan.startsOn, plan.endsOn)} · ${plan.itemsCount} ${plan.itemsCount == 1 ? 'item' : 'itens'}${current ? ' · esta semana' : ''}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do plano',
            onSelected: (action) async {
              if (action == 'copy') {
                await _copyToWeek(context, ref);
              } else if (action == 'delete') {
                await _delete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('Usar em outra semana')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyToWeek(BuildContext context, WidgetRef ref) async {
    final week = await pickWeek(context);
    if (week == null || !context.mounted) return;
    try {
      final created = await ref.read(planningRepositoryProvider).createPlan(week: week, copyFrom: plan.id);
      ref.invalidate(mealPlansProvider);
      if (context.mounted) unawaited(context.push(AppRoutes.mealPlan(created.id)));
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Excluir plano?',
      message: 'O plano "${plan.title}" e sua lista de compras serão apagados. Os registros do diário continuam.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(planningRepositoryProvider).deletePlan(plan.id);
      ref.invalidate(mealPlansProvider);
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

/// Escolhe a semana: esta, a próxima ou a seguinte.
Future<DateTime?> pickWeek(BuildContext context) {
  final thisWeek = mondayOf(DateTime.now());
  final options = [
    (label: 'Esta semana', monday: thisWeek),
    (label: 'Próxima semana', monday: thisWeek.add(const Duration(days: 7))),
    (label: 'Daqui a duas semanas', monday: thisWeek.add(const Duration(days: 14))),
  ];
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Para qual semana?', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          for (final o in options)
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(o.label),
              subtitle: Text(weekRange(o.monday, o.monday.add(const Duration(days: 6)))),
              onTap: () => Navigator.of(context).pop(o.monday),
            ),
        ],
      ),
    ),
  );
}

/// Cria um plano vazio na semana escolhida e abre o plano.
Future<void> createPlanFlow(BuildContext context, WidgetRef ref, List<MealPlanSummary> existing) async {
  final week = await pickWeek(context);
  if (week == null || !context.mounted) return;
  final already = existing.where((p) => p.startsOn == week).firstOrNull;
  if (already != null) {
    unawaited(context.push(AppRoutes.mealPlan(already.id)));
    return;
  }
  try {
    final created = await ref.read(planningRepositoryProvider).createPlan(week: week);
    ref.invalidate(mealPlansProvider);
    if (context.mounted) unawaited(context.push(AppRoutes.mealPlan(created.id)));
  } on Object catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}
