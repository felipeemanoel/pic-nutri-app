import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';
import 'favorite_meal_action.dart';
import 'repeat_meal_sheet.dart';

/// Diário alimentar do dia selecionado: resumo, macronutrientes e refeições.
class FoodPage extends ConsumerWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final meals = ref.watch(mealsOnDayProvider(day));
    final summary = ref.watch(nutritionSummaryProvider(day));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentação'),
        actions: [
          IconButton(
            tooltip: 'Plano alimentar',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push(AppRoutes.mealPlans),
          ),
          IconButton(
            tooltip: 'Registrar por foto',
            icon: Icon(Icons.photo_camera_outlined, color: context.pic.ai),
            onPressed: () => context.push(AppRoutes.mealPhoto),
          ),
          const ProfileButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => chooseHowToAddMeal(context),
        icon: const Icon(Icons.add),
        label: const Text('Refeição'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(mealsOnDayProvider(day))
            ..invalidate(nutritionSummaryProvider(day));
          await ref.read(mealsOnDayProvider(day).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.fabClearance,
          ),
          children: [
            const DayNavigator(),
            summary.maybeWhen(
              data: (s) => _SummaryCard(summary: s),
              orElse: () => const SkeletonCard(lines: 2),
            ),
            SectionHeader(
              title: 'Refeições',
              actionLabel: 'Ver favoritas',
              onAction: () => showFavoriteMealsSheet(context),
            ),
            AsyncValueView<List<Meal>>(
              value: meals,
              onRetry: () => ref.invalidate(mealsOnDayProvider(day)),
              loading: const SkeletonCard(),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Nenhuma refeição neste dia',
                      message:
                          'Registre o que você comeu para acompanhar calorias e macronutrientes.',
                      actionLabel: 'Registrar refeição',
                      onAction: () => chooseHowToAddMeal(context),
                    )
                  : Column(
                      children: [
                        for (final meal in list) ...[
                          _MealTile(meal: meal),
                          const SizedBox(height: Space.sm),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escolha da forma de registro: foto ou texto/voz (estimativa por IA),
/// refeição favorita ou manual.
Future<void> chooseHowToAddMeal(BuildContext context) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Space.sm, bottom: Space.md),
              child: Text(
                'Como deseja registrar?',
                style: sheet.text.titleMedium,
              ),
            ),
            _AddOption(
              icon: Icons.photo_camera_outlined,
              title: 'Por foto',
              subtitle:
                  'A IA estima os alimentos e você revisa antes de salvar',
              ai: true,
              onTap: () => Navigator.of(sheet).pop(AppRoutes.mealPhoto),
            ),
            const SizedBox(height: Space.sm),
            _AddOption(
              icon: Icons.mic_none_rounded,
              title: 'Por texto ou voz',
              subtitle: 'Descreva o que comeu; a IA estima e você revisa',
              ai: true,
              onTap: () => Navigator.of(sheet).pop(AppRoutes.mealText),
            ),
            const SizedBox(height: Space.sm),
            _AddOption(
              icon: Icons.replay_rounded,
              title: 'Repetir refeição',
              subtitle: 'Escolha uma refeição recente e revise antes de registrar',
              onTap: () => Navigator.of(sheet).pop(_repeatRoute),
            ),
            const SizedBox(height: Space.sm),
            _AddOption(
              icon: Icons.star_outline_rounded,
              title: 'Refeição favorita',
              subtitle: 'Registre de novo uma refeição salva',
              onTap: () => Navigator.of(sheet).pop(_favoritesRoute),
            ),
            const SizedBox(height: Space.sm),
            _AddOption(
              icon: Icons.edit_note,
              title: 'Manualmente',
              subtitle: 'Busque no banco de alimentos ou informe os valores',
              onTap: () => Navigator.of(sheet).pop(AppRoutes.newMeal),
            ),
          ],
        ),
      ),
    ),
  );
  if (route == null || !context.mounted) return;
  if (route == _favoritesRoute) {
    await showFavoriteMealsSheet(context);
  } else if (route == _repeatRoute) {
    await showRecentMealsSheet(context);
  } else {
    await context.push(route);
  }
}

const _favoritesRoute = '#favorites';
const _repeatRoute = '#repeat';

/// Lista de refeições favoritas; um toque registra a refeição agora.
Future<void> showFavoriteMealsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.75,
        child: _FavoriteMeals(),
      ),
    );

class _FavoriteMeals extends ConsumerStatefulWidget {
  const _FavoriteMeals();

  @override
  ConsumerState<_FavoriteMeals> createState() => _FavoriteMealsState();
}

class _FavoriteMealsState extends ConsumerState<_FavoriteMeals> {
  String? _busyId;

  Future<void> _addFavorite() async {
    final meal = await showModalBottomSheet<Meal>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.8,
        child: _ChooseFavoriteMeal(),
      ),
    );
    if (meal != null && mounted) await saveFavoriteMeal(context, ref, meal);
  }

  Future<void> _log(MealTemplate t) async {
    setState(() => _busyId = t.id);
    final day = ref.read(selectedDateProvider);
    final now = DateTime.now();
    final isToday = day == SelectedDate.today();
    try {
      await ref
          .read(foodRepositoryProvider)
          .logTemplate(
            t.id,
            requestId: newRequestId(),
            eatenAt: isToday
                ? null
                : DateTime(day.year, day.month, day.day, now.hour, now.minute),
          );
      Refresh.nutrition(ref);
      ref.invalidate(mealTemplatesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, '"${t.name}" registrada.');
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _remove(MealTemplate t) async {
    final ok = await confirmAction(
      context,
      title: 'Remover dos favoritos?',
      message: 'As refeições já registradas continuam no diário.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(foodRepositoryProvider).deleteTemplate(t.id);
      ref.invalidate(mealTemplatesProvider);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(mealTemplatesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Refeições favoritas', style: context.text.titleMedium),
          const SizedBox(height: Space.xs),
          Text(
            'Suas combinações salvas, prontas para usar de novo.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            onPressed: _busyId == null ? _addFavorite : null,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Adicionar favorita'),
          ),
          const SizedBox(height: Space.md),
          Expanded(
            child: AsyncValueView<List<MealTemplate>>(
              value: templates,
              onRetry: () => ref.invalidate(mealTemplatesProvider),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.star_outline_rounded,
                      title: 'Suas favoritas começam aqui',
                      message:
                          'Escolha uma refeição do diário para guardar os alimentos e as quantidades.',
                      actionLabel: 'Escolher do diário',
                      onAction: _addFavorite,
                    )
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Space.sm),
                      itemBuilder: (context, i) {
                        final t = list[i];
                        return AppCard(
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            Space.md,
                            Space.xs,
                            Space.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: context.text.titleSmall,
                                    ),
                                    Text(
                                      t.itemNames.join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodySmall,
                                    ),
                                    Text(
                                      Fmt.kcal(t.totals.energyKcal),
                                      style: context.text.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (_busyId != t.id)
                                TextButton(
                                  onPressed: _busyId == null
                                      ? () => _log(t)
                                      : null,
                                  child: const Text('Registrar'),
                                ),
                              if (_busyId == t.id)
                                const Padding(
                                  padding: EdgeInsets.all(Space.md),
                                  child: SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Remover dos favoritos',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _busyId == null
                                      ? () => _remove(t)
                                      : null,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'O botão Registrar adiciona a refeição ao diário de ${Fmt.dayMonth(ref.watch(selectedDateProvider))}.',
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}

/// A lista de favoritas permite adicionar sem procurar a estrela no editor.
class _ChooseFavoriteMeal extends ConsumerWidget {
  const _ChooseFavoriteMeal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final meals = ref.watch(mealsOnDayProvider(day));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Escolher do diário', style: context.text.titleMedium),
          const SizedBox(height: Space.xs),
          Text(
            'Selecione uma refeição para salvar como favorita.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.sm),
          const DayNavigator(),
          const SizedBox(height: Space.sm),
          Expanded(
            child: AsyncValueView<List<Meal>>(
              value: meals,
              onRetry: () => ref.invalidate(mealsOnDayProvider(day)),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Nenhuma refeição neste dia',
                      message:
                          'Escolha outro dia acima ou registre uma refeição primeiro. Depois você pode salvá-la como favorita.',
                    )
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final meal = list[index];
                        return ListTile(
                          title: Text(meal.displayName),
                          subtitle: Text(
                            meal.items.map((i) => i.name).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.star_outline_rounded),
                          onTap: () => Navigator.of(context).pop(meal),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.md),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.push(AppRoutes.newMeal);
                  if (context.mounted) ref.invalidate(mealsOnDayProvider(day));
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar nova refeição'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.ai = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ai ? p.aiContainer : p.brandContainer,
              borderRadius: Radii.control,
            ),
            child: Icon(icon, color: ai ? p.ai : context.colors.primary),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final NutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = summary.totals;
    final goal = summary.goalKcal;
    final hasGoal = goal != null && goal > 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calorias', style: context.text.labelSmall),
                    MetricValue(value: Fmt.integer(t.energyKcal), unit: 'kcal'),
                  ],
                ),
              ),
              if (hasGoal)
                Text(
                  'meta ${Fmt.kcal(goal)}',
                  style: context.text.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          if (hasGoal) ...[
            const SizedBox(height: Space.sm),
            ProgressBar(progress: t.energyKcal / goal),
          ],
          const SizedBox(height: Space.lg),
          MacroSummary(
            proteinG: t.proteinG,
            carbsG: t.carbsG,
            fatG: t.fatG,
            proteinGoal: summary.goalProteinG,
            carbsGoal: summary.goalCarbsG,
            fatGoal: summary.goalFatG,
          ),
        ],
      ),
    );
  }
}

class _MealTile extends ConsumerWidget {
  const _MealTile({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromPhoto = meal.source == 'ai_photo';
    return AppCard(
      onTap: () => context.push(AppRoutes.editMeal, extra: meal),
      semanticLabel:
          '${meal.displayName}, ${Fmt.kcal(meal.totals.energyKcal)}. Toque para editar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(meal.displayName, style: context.text.titleSmall),
              ),
              if (fromPhoto) ...[
                const AiBadge(label: 'Por foto', compact: false),
                const SizedBox(width: Space.sm),
              ],
              Text(Fmt.time(meal.eatenAt), style: context.text.bodySmall),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            meal.items.map((i) => i.name).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
          Wrap(
            spacing: Space.xs,
            children: [
              TextButton.icon(
                onPressed: () => repeatMeal(context, meal),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Repetir'),
              ),
              TextButton.icon(
                onPressed: () => saveFavoriteMeal(context, ref, meal),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Salvar favorita'),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Text(
                Fmt.kcal(meal.totals.energyKcal),
                style: context.text.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  'P ${Fmt.grams(meal.totals.proteinG)} · C ${Fmt.grams(meal.totals.carbsG)} · G ${Fmt.grams(meal.totals.fatG)}',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
