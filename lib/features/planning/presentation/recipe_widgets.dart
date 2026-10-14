import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../food/data/nutrition_models.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';

/// Linha de receita com calorias e macros por porção.
class RecipeTile extends StatelessWidget {
  const RecipeTile({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = recipe.perServing;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.menu_book_rounded, color: context.colors.primary),
        title: Text(recipe.title),
        subtitle: Text(
          [
            '${Fmt.kcal(n.energyKcal)}/porção',
            'P ${Fmt.grams(n.proteinG)}',
            if (recipe.prepMinutes != null) '${recipe.prepMinutes} min',
          ].join(' · '),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Lembrete de conferir ingredientes: as sugestões não verificam alergias.
class AllergyNotice extends StatelessWidget {
  const AllergyNotice({super.key});

  @override
  Widget build(BuildContext context) => const StatusBanner(
    icon: Icons.info_outline,
    message:
        'Se você tem alergia ou intolerância, confira os ingredientes de cada receita. As sugestões excluem apenas os alimentos que você informou evitar.',
  );
}

/// Lista de receitas com busca e filtro de refeição.
class RecipeBrowser extends ConsumerStatefulWidget {
  const RecipeBrowser({super.key, required this.onSelect, this.initialMealType});

  final void Function(Recipe recipe) onSelect;
  final String? initialMealType;

  @override
  ConsumerState<RecipeBrowser> createState() => _RecipeBrowserState();
}

class _RecipeBrowserState extends ConsumerState<RecipeBrowser> {
  final _search = TextEditingController();
  Timer? _debounce;
  late String? _mealType = widget.initialMealType;
  String _term = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RecipeQuery query = (search: _term, mealType: _mealType);
    final recipes = ref.watch(recipesProvider(query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Buscar receita',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _term = v.trim()));
            },
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.sm),
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _mealType == null,
                onSelected: (_) => setState(() => _mealType = null),
              ),
              for (final e in MealTypes.labels.entries)
                if (e.key != 'other')
                  Padding(
                    padding: const EdgeInsets.only(left: Space.xs),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _mealType == e.key,
                      onSelected: (_) => setState(() => _mealType = e.key),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueView<List<Recipe>>(
            value: recipes,
            onRetry: () => ref.invalidate(recipesProvider(query)),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.menu_book_outlined,
                    title: 'Nenhuma receita encontrada',
                    message: 'Tente outro termo ou outra refeição.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
                    children: [
                      for (final r in list) RecipeTile(recipe: r, onTap: () => widget.onSelect(r)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Abre a lista de receitas em uma folha e devolve a escolhida.
Future<Recipe?> showRecipePicker(BuildContext context, {String? mealType}) => showModalBottomSheet<Recipe>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: 0.9,
    child: RecipeBrowser(
      initialMealType: mealType,
      onSelect: (r) => Navigator.of(context).pop(r),
    ),
  ),
);
