import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../food/data/nutrition_models.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';
import 'meal_plan_page.dart';
import 'recipe_widgets.dart';

/// Receitas publicadas pela equipe.
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Receitas')),
    body: Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: RecipeBrowser(onSelect: (r) => context.push(AppRoutes.recipe(r.id))),
    ),
  );
}

/// Detalhe da receita: ingredientes, preparo e valores por porção.
class RecipePage extends ConsumerWidget {
  const RecipePage({super.key, required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeProvider(recipeId));
    return Scaffold(
      appBar: AppBar(title: const Text('Receita')),
      bottomNavigationBar: recipe.hasValue
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.md),
                child: FilledButton.icon(
                  onPressed: () => addRecipeToPlanFlow(context, ref, recipe.requireValue),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Adicionar ao plano'),
                ),
              ),
            )
          : null,
      body: AsyncValueView<Recipe>(
        value: recipe,
        onRetry: () => ref.invalidate(recipeProvider(recipeId)),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
          children: [
            Semantics(header: true, child: Text(r.title, style: context.text.headlineSmall)),
            if (r.summary != null) ...[
              const SizedBox(height: Space.xs),
              Text(r.summary!, style: context.text.bodyMedium),
            ],
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                Chip(label: Text(r.servings == 1 ? 'Rende 1 porção' : 'Rende ${r.servings} porções')),
                if (r.prepMinutes != null) Chip(label: Text('${r.prepMinutes} min')),
                for (final t in r.mealTypes) Chip(label: Text(MealTypes.label(t))),
                for (final t in r.tags) Chip(label: Text(t)),
              ],
            ),
            const SectionHeader(title: 'Por porção'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricValue(value: Fmt.integer(r.perServing.energyKcal), unit: 'kcal'),
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
            const SectionHeader(title: 'Ingredientes'),
            for (final i in r.ingredients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.circle, size: 8),
                title: Text(i.name),
                subtitle: Text(i.amountLabel),
              ),
            const SectionHeader(title: 'Modo de preparo'),
            Text(r.instructions ?? '', style: context.text.bodyMedium),
            const SizedBox(height: Space.lg),
            const AllergyNotice(),
          ],
        ),
      ),
    );
  }
}
