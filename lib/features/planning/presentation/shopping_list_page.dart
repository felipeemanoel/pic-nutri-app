import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';

/// Lista de compras gerada do plano, agrupada por grupo de alimentos.
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  /// Marcações locais aplicadas antes da resposta da API (resposta rápida).
  Set<int>? _checked;

  Set<int> _fromServer(List<ShoppingGroup> groups) => {
    for (final g in groups)
      for (final i in g.items)
        if (i.checked) i.foodId,
  };

  Future<void> _toggle(List<ShoppingGroup> groups, int foodId, bool value) async {
    final previous = _checked ?? _fromServer(groups);
    final next = {...previous};
    value ? next.add(foodId) : next.remove(foodId);
    setState(() => _checked = next);
    try {
      await ref.read(planningRepositoryProvider).setChecked(widget.planId, next);
      ref.invalidate(shoppingListProvider(widget.planId));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _checked = previous);
      showFailure(context, e);
    }
  }

  Future<void> _share(List<ShoppingGroup> groups, Set<int> checked) async {
    final buffer = StringBuffer('Lista de compras — PicNutri\n');
    for (final g in groups) {
      final pending = g.items.where((i) => !checked.contains(i.foodId)).toList();
      if (pending.isEmpty) continue;
      buffer.writeln('\n${g.category}');
      for (final i in pending) {
        buffer.writeln('• ${i.name} — ${Fmt.decimal(i.quantity)} ${i.unit}');
      }
    }
    await SharePlus.instance.share(ShareParams(text: buffer.toString(), subject: 'Lista de compras'));
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(shoppingListProvider(widget.planId));
    final groups = list.value;
    final checked = _checked ?? (groups == null ? <int>{} : _fromServer(groups));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          if (groups != null && groups.isNotEmpty)
            IconButton(
              tooltip: 'Compartilhar',
              icon: const Icon(Icons.ios_share),
              onPressed: () => _share(groups, checked),
            ),
        ],
      ),
      body: AsyncValueView<List<ShoppingGroup>>(
        value: list,
        onRetry: () => ref.invalidate(shoppingListProvider(widget.planId)),
        data: (groups) => groups.isEmpty
            ? const EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Lista vazia',
                message: 'Adicione receitas ou alimentos ao plano para gerar a lista de compras.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
                children: [
                  Text(
                    'Quantidades somadas do plano da semana, em peso ou volume do alimento como consumido na receita. Ajuste conforme o que você já tem em casa.',
                    style: context.text.bodySmall,
                  ),
                  _ExtraRecipes(planId: widget.planId),
                  for (final g in groups) ...[
                    SectionHeader(title: g.category),
                    for (final i in g.items)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: checked.contains(i.foodId),
                        onChanged: (v) => _toggle(groups, i.foodId, v ?? false),
                        title: Text(
                          i.name,
                          style: checked.contains(i.foodId)
                              ? TextStyle(decoration: TextDecoration.lineThrough, color: context.pic.textSecondary)
                              : null,
                        ),
                        subtitle: Text('${Fmt.decimal(i.quantity)} ${i.unit}'),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Receitas adicionadas só à lista (sem planejar a refeição), com opção de tirar.
class _ExtraRecipes extends ConsumerWidget {
  const _ExtraRecipes({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extras = ref.watch(shoppingExtrasProvider(planId)).value ?? const <ShoppingExtraRecipe>[];
    if (extras.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Receitas só na lista'),
        for (final e in extras)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(e.title),
            subtitle: Text('${Fmt.decimal(e.servings)} porções · não planejada'),
            trailing: IconButton(
              tooltip: 'Tirar ${e.title} da lista',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () async {
                try {
                  await ref.read(planningRepositoryProvider).removeRecipeFromShopping(planId, e.recipeId);
                  ref
                    ..invalidate(shoppingListProvider(planId))
                    ..invalidate(shoppingExtrasProvider(planId));
                } on Object catch (err) {
                  if (context.mounted) showFailure(context, err);
                }
              },
            ),
          ),
      ],
    );
  }
}

