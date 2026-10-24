import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../food/data/nutrition_models.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';

/// Capa padronizada da receita (4:3). Sem foto, mostra uma ilustração
/// identificada como tal — nunca sugere ser a foto do prato.
class RecipeCover extends StatelessWidget {
  const RecipeCover({super.key, required this.recipe, this.radius = Radii.lg});

  final Recipe recipe;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = recipe.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: url == null
            ? _Illustration(recipe: recipe)
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: 'Foto da receita ${recipe.title}',
                errorBuilder: (_, _, _) => _Illustration(recipe: recipe),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : ColoredBox(color: context.pic.surfaceMuted),
              ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.recipe});

  final Recipe recipe;

  IconData get _icon => switch (recipe.mealTypes.firstOrNull) {
    'breakfast' || 'supper' => Icons.free_breakfast_rounded,
    'lunch' || 'dinner' => Icons.dinner_dining_rounded,
    _ => Icons.bakery_dining_rounded,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ilustração (receita sem foto)',
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.pic.brandContainer, context.pic.surfaceMuted],
        ),
      ),
      child: Stack(
        children: [
          Center(child: Icon(_icon, size: 56, color: context.colors.primary.withValues(alpha: 0.7))),
          Positioned(
            left: Space.sm,
            bottom: Space.sm,
            child: Text('Ilustração', style: context.text.labelSmall),
          ),
        ],
      ),
    ),
  );
}

/// Tempo, porções e calorias por porção, em uma linha legível.
String recipeFacts(Recipe r) => [
  if (r.prepMinutes != null) '${r.prepMinutes} min',
  r.servings == 1 ? '1 porção' : '${r.servings} porções',
  '${Fmt.kcal(r.perServing.energyKcal)}/porção',
].join(' · ');

/// Cartão de receita: capa, título, tempo, porções e botão de salvar.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap, this.onFavorite});

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${recipe.title}. ${recipeFacts(recipe)}.${recipe.isFavorite ? ' Salva.' : ''}',
    excludeSemantics: true,
    child: Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: Radii.card, side: BorderSide(color: context.pic.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  RecipeCover(recipe: recipe),
                  if (onFavorite != null)
                    Positioned(
                      right: Space.xs,
                      top: Space.xs,
                      child: IconButton.filledTonal(
                        tooltip: recipe.isFavorite ? 'Remover das salvas' : 'Salvar receita',
                        onPressed: onFavorite,
                        icon: Icon(recipe.isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(recipe.title, style: context.text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Space.xs),
              Text(recipeFacts(recipe), style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Linha compacta (seletor de receitas do planejamento).
class RecipeTile extends StatelessWidget {
  const RecipeTile({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(width: 72, child: RecipeCover(recipe: recipe, radius: Radii.sm)),
      title: Text(recipe.title),
      subtitle: Text(recipeFacts(recipe)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    ),
  );
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

/// Receitas com busca e filtros: salvas, preparo rápido, refeição e etiquetas.
///
/// [compact] usa linhas (seletor do planejamento); sem ele, cartões com foto.
class RecipeBrowser extends ConsumerStatefulWidget {
  const RecipeBrowser({super.key, required this.onSelect, this.initialMealType, this.compact = false});

  final void Function(Recipe recipe) onSelect;
  final String? initialMealType;
  final bool compact;

  @override
  ConsumerState<RecipeBrowser> createState() => _RecipeBrowserState();
}

class _RecipeBrowserState extends ConsumerState<RecipeBrowser> {
  static const quickMinutes = 30;

  final _search = TextEditingController();
  Timer? _debounce;
  late String? _mealType = widget.initialMealType;
  String _term = '';
  String? _tag;
  bool _quick = false;
  bool _favorites = false;

  RecipeFilters get _filters =>
      (search: _term, mealType: _mealType, tag: _tag, maxMinutes: _quick ? quickMinutes : null, favorites: _favorites);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Recipe r) async {
    try {
      await ref.read(planningRepositoryProvider).setRecipeFavorite(r.id, !r.isFavorite);
      ref.invalidate(recipeSearchProvider);
      ref.invalidate(recipeProvider(r.id));
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: Space.xs),
    child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
  );

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final results = ref.watch(recipeSearchProvider(filters));
    final tags = results.value?.tags ?? const <String>[];
    final filtered = _favorites || _quick || _mealType != null || _tag != null || _term.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(hintText: 'Buscar receita', prefixIcon: Icon(Icons.search)),
            textInputAction: TextInputAction.search,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _term = v.trim()));
            },
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.sm),
            children: [
              _chip('Salvas', _favorites, () => setState(() => _favorites = !_favorites)),
              _chip('Até $quickMinutes min', _quick, () => setState(() => _quick = !_quick)),
              for (final e in MealTypes.labels.entries)
                if (e.key != 'other')
                  _chip(e.value, _mealType == e.key, () => setState(() => _mealType = _mealType == e.key ? null : e.key)),
              for (final t in tags) _chip(t, _tag == t, () => setState(() => _tag = _tag == t ? null : t)),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueView<RecipeResults>(
            value: results,
            onRetry: () => ref.invalidate(recipeSearchProvider(filters)),
            data: (page) => page.recipes.isEmpty
                ? EmptyState(
                    compact: true,
                    icon: _favorites ? Icons.bookmark_border_rounded : Icons.menu_book_outlined,
                    title: _favorites ? 'Nenhuma receita salva' : 'Nenhuma receita encontrada',
                    message: _favorites
                        ? 'Toque no marcador de uma receita para salvá-la aqui.'
                        : filtered
                        ? 'Tente outro termo ou remova um filtro.'
                        : 'As receitas publicadas pela equipe aparecem aqui.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, Space.xxl),
                    itemCount: page.recipes.length,
                    separatorBuilder: (_, _) => SizedBox(height: widget.compact ? 0 : Space.lg),
                    itemBuilder: (context, i) {
                      final r = page.recipes[i];
                      return widget.compact
                          ? RecipeTile(recipe: r, onTap: () => widget.onSelect(r))
                          : RecipeCard(recipe: r, onTap: () => widget.onSelect(r), onFavorite: () => _toggleFavorite(r));
                    },
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
      compact: true,
      initialMealType: mealType,
      onSelect: (r) => Navigator.of(context).pop(r),
    ),
  ),
);
