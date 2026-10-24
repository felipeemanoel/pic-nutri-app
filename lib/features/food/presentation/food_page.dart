import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/features.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../planning/presentation/recipes_page.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';
import 'favorite_meal_action.dart';
import 'meal_editor_page.dart';
import 'repeat_meal_sheet.dart';

/// Diário alimentar completo: qualquer dia, resumo com macronutrientes,
/// refeições e, abaixo, plano alimentar e receitas. Registrar é sempre pelo
/// botão "Registrar refeição", que reúne todas as formas em um só lugar.
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
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => chooseHowToAddMeal(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar refeição'),
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
            const SizedBox(height: Space.md),
            summary.maybeWhen(
              data: (s) => _SummaryCard(summary: s),
              orElse: () => const SkeletonCard(lines: 2),
            ),
            const SizedBox(height: Space.lg),
            const SectionHeader(title: 'Refeições do dia'),
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
            const SizedBox(height: Space.section),
            const SectionHeader(title: 'Planejar e cozinhar'),
            const _PlanAndRecipes(),
          ],
        ),
      ),
    );
  }
}

/// Plano alimentar e receitas com rótulo visível (antes eram só um ícone na
/// barra e um atalho com nome diferente do destino).
class _PlanAndRecipes extends StatelessWidget {
  const _PlanAndRecipes();

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Shortcut(
            icon: Icons.calendar_month_outlined,
            label: 'Plano alimentar',
            onTap: () => context.push(AppRoutes.mealPlans),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: _Shortcut(
            icon: Icons.menu_book_outlined,
            label: 'Receitas e conteúdos',
            onTap: () => context.push(AppRoutes.contents),
          ),
        ),
      ],
    ),
  );
}

/// Atalho de mesmo peso visual (ícone sobre o rótulo).
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.control,
        side: BorderSide(color: context.pic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xs,
            vertical: Space.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.colors.primary),
              const SizedBox(height: Space.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.labelMedium,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ponto único de registro de refeição (Início e Alimentação): formas disponíveis
/// de registro e, abaixo, repetir uma recente ou favorita com um toque.
Future<void> chooseHowToAddMeal(BuildContext context) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Space.sm, bottom: Space.md),
              child: Semantics(
                header: true,
                child: Text(
                  'Registrar refeição',
                  style: sheet.text.titleMedium,
                ),
              ),
            ),
            _AddOption(
              icon: Icons.photo_camera_outlined,
              title: 'Tirar foto do prato',
              subtitle: 'A IA estima os alimentos e você revisa',
              ai: true,
              onTap: () => Navigator.of(sheet).pop(AppRoutes.mealPhoto),
            ),
            const SizedBox(height: Space.sm),
            _AddOption(
              icon: Icons.search_rounded,
              title: 'Buscar alimentos',
              subtitle:
                  'No banco de alimentos, pelo código de barras ou informando os valores',
              onTap: () => Navigator.of(sheet).pop(_searchRoute),
            ),
            // Mantido OFF: texto/voz serão retomados em uma etapa futura.
            if (AppFeatures.mealTextVoice) ...[
              const SizedBox(height: Space.sm),
              _AddOption(
                icon: Icons.mic_none_rounded,
                title: 'Falar ou escrever',
                subtitle: 'Conte o que comeu; a IA estima e você revisa',
                ai: true,
                onTap: () => Navigator.of(sheet).pop(AppRoutes.mealText),
              ),
            ],
            const SizedBox(height: Space.lg),
            Padding(
              padding: const EdgeInsets.only(left: Space.sm, bottom: Space.sm),
              child: Text('Comer de novo', style: sheet.text.labelLarge),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Shortcut(
                      icon: Icons.replay_rounded,
                      label: 'Recentes',
                      onTap: () => Navigator.of(sheet).pop(_repeatRoute),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _Shortcut(
                      icon: Icons.star_outline_rounded,
                      label: 'Favoritas',
                      onTap: () => Navigator.of(sheet).pop(_favoritesRoute),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (route == null || !context.mounted) return;
  switch (route) {
    case _favoritesRoute:
      await showFavoriteMealsSheet(context);
    case _repeatRoute:
      await showRecentMealsSheet(context);
    case _searchRoute:
      await context.push(AppRoutes.newMeal, extra: MealEditorStart.search);
    default:
      await context.push(route);
  }
}

const _favoritesRoute = '#favorites';
const _repeatRoute = '#repeat';
const _searchRoute = '#search';

/// Refeições favoritas; um toque abre a revisão (quantidades) antes de registrar.
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

  /// Mesma revisão de "Repetir refeição": alimentos e quantidades preenchidos,
  /// no dia selecionado; só grava ao tocar em "Registrar refeição".
  Future<void> _log(MealTemplate t) async {
    if (t.items.isEmpty) return;
    Navigator.of(context).pop();
    await context.push(
      AppRoutes.recipeMeal,
      extra: RecipeMealDraft(
        title: t.name,
        items: t.items,
        mealType: t.mealType,
      ),
    );
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
                child: Text(meal.displayName, style: context.text.titleMedium),
              ),
              if (fromPhoto) ...[
                const AiBadge(label: 'Por foto', compact: false),
                const SizedBox(width: Space.sm),
              ],
              Text(Fmt.time(meal.eatenAt), style: context.text.bodySmall),
              PopupMenuButton<String>(
                tooltip: 'Mais ações',
                onSelected: (v) => v == 'repeat'
                    ? repeatMeal(context, meal)
                    : saveFavoriteMeal(context, ref, meal),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'repeat',
                    child: Text('Repetir refeição'),
                  ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Text('Salvar como favorita'),
                  ),
                ],
              ),
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
