import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../assistant/presentation/chat_page.dart';
import '../../food/data/nutrition_models.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';
import 'meal_plan_page.dart';
import 'plans_page.dart';
import 'recipe_widgets.dart';

/// Rascunho de refeição a partir de uma receita, revisado antes de registrar.
class RecipeMealDraft {
  const RecipeMealDraft({
    required this.title,
    required this.items,
    this.mealType,
  });

  final String title;
  final List<MealItem> items;
  final String? mealType;
}

/// Receitas publicadas pela equipe, com busca e filtros.
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Receitas')),
    body: Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: RecipeBrowser(
        onSelect: (r) => context.push(AppRoutes.recipe(r.id)),
      ),
    ),
  );
}

/// "Comi esta receita": pergunta as porções e abre a revisão preenchida.
/// Nada é gravado até a pessoa tocar em "Registrar refeição".
Future<void> logRecipeFlow(BuildContext context, Recipe recipe) async {
  final eaten = await askServings(
    context,
    recipe.title,
    question: 'Quantas porções você comeu?',
    confirmLabel: 'Revisar',
  );
  if (eaten == null || !context.mounted) return;
  await context.push(
    AppRoutes.recipeMeal,
    extra: RecipeMealDraft(
      title: recipe.title,
      items: recipe.itemsFor(eaten),
      mealType: recipe.mealTypes.firstOrNull,
    ),
  );
}

/// Ingredientes na lista de compras de um plano, sem planejar a refeição.
Future<void> addRecipeToShoppingFlow(
  BuildContext context,
  WidgetRef ref,
  Recipe recipe,
) async {
  final repo = ref.read(planningRepositoryProvider);
  try {
    final plans = await ref.read(mealPlansProvider.future);
    if (!context.mounted) return;
    final thisWeek = mondayOf(DateTime.now());
    final target = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.xs,
              ),
              child: Text(
                'Em qual lista de compras?',
                style: context.text.titleMedium,
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
                'Os ingredientes entram na lista do plano escolhido. A receita não é planejada.',
                style: context.text.bodySmall,
              ),
            ),
            for (final p in plans.take(6))
              ListTile(
                leading: const Icon(Icons.shopping_basket_outlined),
                title: Text(p.title),
                subtitle: Text(weekRange(p.startsOn, p.endsOn)),
                onTap: () => Navigator.of(context).pop(p),
              ),
            if (!plans.any((p) => p.startsOn == thisWeek))
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Nova lista desta semana'),
                onTap: () => Navigator.of(context).pop('new'),
              ),
          ],
        ),
      ),
    );
    if (target == null || !context.mounted) return;
    final planId = target is MealPlanSummary
        ? target.id
        : (await repo.createPlan(week: thisWeek)).id;
    await repo.addRecipeToShopping(
      planId,
      recipeId: recipe.id,
      servings: recipe.servings.toDouble(),
    );
    ref
      ..invalidate(mealPlansProvider)
      ..invalidate(shoppingListProvider(planId))
      ..invalidate(shoppingExtrasProvider(planId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Ingredientes adicionados à lista de compras.'),
          action: SnackBarAction(
            label: 'Ver lista',
            onPressed: () => context.push(AppRoutes.shoppingList(planId)),
          ),
        ),
      );
  } on Object catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// Detalhe da receita: foto, autoria e fonte, valores por porção, e ações
/// separadas — registrar consumo, planejar e lista de compras.
class RecipePage extends ConsumerWidget {
  const RecipePage({super.key, required this.recipeId});

  final int recipeId;

  static final _date = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Recipe r,
  ) async {
    try {
      await ref
          .read(planningRepositoryProvider)
          .setRecipeFavorite(r.id, !r.isFavorite);
      ref
        ..invalidate(recipeProvider(r.id))
        ..invalidate(recipeSearchProvider);
      if (context.mounted) {
        showMessage(
          context,
          r.isFavorite ? 'Receita removida das salvas.' : 'Receita salva.',
        );
      }
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeProvider(recipeId));
    final r = recipe.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receita'),
        actions: [
          if (r != null)
            IconButton(
              tooltip: r.isFavorite ? 'Remover das salvas' : 'Salvar receita',
              icon: Icon(
                r.isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              onPressed: () => _toggleFavorite(context, ref, r),
            ),
        ],
      ),
      body: AsyncValueView<Recipe>(
        value: recipe,
        onRetry: () => ref.invalidate(recipeProvider(recipeId)),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.sm,
            Space.page,
            Space.xxxl,
          ),
          children: [
            RecipeCover(recipe: r, radius: Radii.xl),
            const SizedBox(height: Space.lg),
            Semantics(
              header: true,
              child: Text(r.title, style: context.text.headlineSmall),
            ),
            const SizedBox(height: Space.xs),
            Text(
              recipeFacts(r),
              style: context.text.bodyMedium?.copyWith(
                color: context.pic.textSecondary,
              ),
            ),
            if (r.summary != null) ...[
              const SizedBox(height: Space.md),
              Text(r.summary!, style: context.text.bodyMedium),
            ],
            const SizedBox(height: Space.md),
            _Credits(
              recipe: r,
              date: r.updatedAt == null ? null : _date.format(r.updatedAt!),
            ),
            const SizedBox(height: Space.section),
            _Actions(recipe: r),
            const SizedBox(height: Space.section),
            Semantics(
              header: true,
              child: Text('Por porção', style: context.text.titleMedium),
            ),
            const SizedBox(height: Space.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricValue(
                    value: Fmt.integer(r.perServing.energyKcal),
                    unit: 'kcal',
                  ),
                  const SizedBox(height: Space.sm),
                  MacroSummary(
                    proteinG: r.perServing.proteinG,
                    carbsG: r.perServing.carbsG,
                    fatG: r.perServing.fatG,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Calculado a partir dos ingredientes no banco de alimentos (TACO ou rótulo do fabricante).',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.section),
            Semantics(
              header: true,
              child: Text('Ingredientes', style: context.text.titleMedium),
            ),
            const SizedBox(height: Space.xs),
            for (final i in r.ingredients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle, size: 8),
                title: Text(i.name),
                subtitle: Text(i.amountLabel),
              ),
            const SizedBox(height: Space.section),
            Semantics(
              header: true,
              child: Text('Modo de preparo', style: context.text.titleMedium),
            ),
            const SizedBox(height: Space.sm),
            Text(r.instructions ?? '', style: context.text.bodyMedium),
            const SizedBox(height: Space.section),
            const AllergyNotice(),
          ],
        ),
      ),
    );
  }
}

/// Autoria, fonte e data; e a diferença entre sugestão geral e plano profissional.
class _Credits extends StatelessWidget {
  const _Credits({required this.recipe, required this.date});

  final Recipe recipe;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Por ${recipe.author ?? 'Equipe PicNutri'}', style: style),
        if (recipe.source != null)
          Text('Fonte: ${recipe.source}', style: style),
        if (date != null) Text('Atualizada em $date', style: style),
        const SizedBox(height: Space.sm),
        Text(
          'Sugestão geral da equipe PicNutri — não é um plano feito por um profissional para você.',
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

/// Três ações distintas: registrar o que comeu (principal), planejar e lista de compras.
class _Actions extends ConsumerWidget {
  const _Actions({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: () => logRecipeFlow(context, recipe),
        icon: const Icon(Icons.restaurant_rounded),
        label: const Text('Comi esta receita'),
      ),
      const SizedBox(height: Space.sm),
      Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          OutlinedButton.icon(
            onPressed: () => addRecipeToPlanFlow(context, ref, recipe),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Planejar'),
          ),
          OutlinedButton.icon(
            onPressed: () => addRecipeToShoppingFlow(context, ref, recipe),
            icon: const Icon(Icons.shopping_basket_outlined),
            label: const Text('Lista de compras'),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.push(
            AppRoutes.chat,
            extra: const ChatDraft(
              'Quais são minhas metas registradas no PicNutri?',
            ),
          ),
          icon: Icon(Icons.auto_awesome_outlined, color: context.pic.ai),
          label: const Text('Consultar minhas metas'),
        ),
      ),
    ],
  );
}
