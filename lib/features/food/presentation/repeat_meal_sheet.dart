import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';

/// Abre a revisão de uma refeição repetida (novo registro, preenchido).
Future<void> repeatMeal(BuildContext context, Meal meal) =>
    context.push(AppRoutes.repeatMeal, extra: meal);

/// Refeições dos últimos 14 dias; tocar em uma abre a revisão preenchida.
Future<void> showRecentMealsSheet(BuildContext context) async {
  final meal = await showModalBottomSheet<Meal>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RecentMealsSheet(),
  );
  if (meal != null && context.mounted) await repeatMeal(context, meal);
}

/// "Hoje, 12:30", "Ontem, 20:00" ou "seg., 13 de out, 08:15".
String recentMealWhen(DateTime eatenAt, [DateTime? now]) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(eatenAt);
  final label = day == today
      ? 'Hoje'
      : day == today.subtract(const Duration(days: 1))
      ? 'Ontem'
      : Fmt.shortDate(eatenAt);
  return '$label, ${Fmt.time(eatenAt)}';
}

class _RecentMealsSheet extends ConsumerWidget {
  const _RecentMealsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(recentMealsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              0,
              Space.page,
              Space.xs,
            ),
            child: Semantics(
              header: true,
              child: Text('Repetir refeição', style: context.text.titleMedium),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              0,
              Space.page,
              Space.sm,
            ),
            child: Text(
              'Escolha uma refeição recente. Você revisa tudo antes de registrar.',
              style: context.text.bodySmall,
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Meal>>(
              value: meals,
              onRetry: () => ref.invalidate(recentMealsProvider),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_rounded,
                      title: 'Nenhuma refeição recente',
                      message:
                          'As refeições registradas nos últimos 14 dias aparecem aqui para você repetir.',
                    )
                  : ListView.separated(
                      controller: scroll,
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final meal = list[i];
                        final type =
                            MealTypes.labels[meal.mealType] ?? meal.displayName;
                        return ListTile(
                          leading: const Icon(Icons.replay_rounded),
                          title: Text(
                            meal.title?.isNotEmpty ?? false
                                ? '${meal.title} · $type'
                                : type,
                          ),
                          subtitle: Text(
                            '${recentMealWhen(meal.eatenAt)}\n${meal.items.map((it) => it.name).join(', ')}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          onTap: () => Navigator.of(context).pop(meal),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
