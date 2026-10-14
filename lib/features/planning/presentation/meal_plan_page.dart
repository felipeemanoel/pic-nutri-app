import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../food/data/nutrition_models.dart';
import '../../food/presentation/food_picker_sheet.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';
import 'plans_page.dart';
import 'recipe_widgets.dart';

final _weekday = DateFormat('EEE', 'pt_BR');

/// Plano da semana, dia a dia, com totais e ações por item.
class MealPlanPage extends ConsumerWidget {
  const MealPlanPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(mealPlanProvider(planId));
    final data = plan.value;
    if (data != null) return _PlanView(plan: data);
    return Scaffold(
      appBar: AppBar(title: const Text('Plano alimentar')),
      body: AsyncValueView<MealPlan>(
        value: plan,
        onRetry: () => ref.invalidate(mealPlanProvider(planId)),
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final initial = plan.contains(today) ? today.weekday - 1 : 0;

    return DefaultTabController(
      length: 7,
      initialIndex: initial,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.title),
          actions: [
            IconButton(
              tooltip: 'Lista de compras',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.push(AppRoutes.shoppingList(plan.id)),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final d in plan.days)
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_weekday.format(d.date).replaceAll('.', '')),
                      Text('${d.date.day}', style: context.text.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [for (final d in plan.days) _DayView(plan: plan, day: d)],
        ),
      ),
    );
  }
}

class _DayView extends ConsumerWidget {
  const _DayView({required this.plan, required this.day});

  final MealPlan plan;
  final PlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planned = ref.watch(currentAccountProvider)?.profile.plannedMeals ?? const ['breakfast', 'lunch', 'dinner'];
    final byMeal = day.byMeal;
    final types = MealTypes.labels.keys
        .where((t) => planned.contains(t) || byMeal.containsKey(t))
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(mealPlanProvider(plan.id).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
        children: [
          _DayTotals(day: day),
          for (final type in types) ...[
            SectionHeader(title: MealTypes.label(type)),
            for (final item in byMeal[type] ?? const <PlanItem>[])
              _PlanItemTile(plan: plan, item: item),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showAddPlanItemSheet(context, ref, plan: plan, day: day.day, mealType: type),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ),
          ],
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            onPressed: () async {
              final type = await _pickMealType(context, types);
              if (type != null && context.mounted) {
                await showAddPlanItemSheet(context, ref, plan: plan, day: day.day, mealType: type);
              }
            },
            icon: const Icon(Icons.playlist_add),
            label: const Text('Outra refeição'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickMealType(BuildContext context, List<String> shown) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final e in MealTypes.labels.entries)
            if (!shown.contains(e.key))
              ListTile(title: Text(e.value), onTap: () => Navigator.of(context).pop(e.key)),
        ],
      ),
    ),
  );
}

class _DayTotals extends StatelessWidget {
  const _DayTotals({required this.day});

  final PlanDay day;

  @override
  Widget build(BuildContext context) {
    final goal = day.goalKcal;
    final kcal = day.totals.energyKcal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_capitalize(Fmt.fullDate(day.date)), style: context.text.bodySmall),
          const SizedBox(height: Space.xs),
          Text(
            goal == null ? '${Fmt.kcal(kcal)} planejadas' : '${Fmt.kcal(kcal)} de ${Fmt.kcal(goal)} planejadas',
            style: context.text.titleMedium,
          ),
          if (goal != null && goal > 0) ...[
            const SizedBox(height: Space.sm),
            ProgressBar(progress: (kcal / goal).clamp(0, 1).toDouble()),
          ],
          const SizedBox(height: Space.sm),
          Text(
            'P ${Fmt.grams(day.totals.proteinG)} · C ${Fmt.grams(day.totals.carbsG)} · G ${Fmt.grams(day.totals.fatG)}',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _PlanItemTile extends ConsumerWidget {
  const _PlanItemTile({required this.plan, required this.item});

  final MealPlan plan;
  final PlanItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = item.nutrients;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        leading: Icon(
          item.kind == 'recipe' ? Icons.menu_book_rounded : Icons.restaurant_rounded,
          color: item.isAvailable ? context.colors.primary : context.pic.textSecondary,
        ),
        title: Text(item.title),
        subtitle: Text(
          [
            item.amountLabel,
            if (n != null) Fmt.kcal(n.energyKcal),
            if (item.note != null && item.note!.isNotEmpty) item.note!,
          ].join(' · '),
        ),
        onTap: item.kind == 'recipe' && item.recipeId != null
            ? () => context.push(AppRoutes.recipe(item.recipeId!))
            : null,
        trailing: PopupMenuButton<String>(
          tooltip: 'Ações do item',
          onSelected: (action) => switch (action) {
            'log' => _log(context, ref),
            _ => _remove(context, ref),
          },
          itemBuilder: (_) => [
            if (item.isAvailable) const PopupMenuItem(value: 'log', child: Text('Registrar no diário agora')),
            const PopupMenuItem(value: 'remove', child: Text('Remover do plano')),
          ],
        ),
      ),
    );
  }

  Future<void> _log(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(planningRepositoryProvider).logItem(plan.id, item.id, requestId: newRequestId());
      Refresh.nutrition(ref);
      if (context.mounted) showMessage(context, '${item.title} registrado no diário.');
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(planningRepositoryProvider).removeItem(plan.id, item.id);
      _refreshPlan(ref, plan.id);
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

void _refreshPlan(WidgetRef ref, String planId) {
  ref
    ..invalidate(mealPlanProvider(planId))
    ..invalidate(shoppingListProvider(planId))
    ..invalidate(mealPlansProvider);
}

/// Adiciona item a uma refeição do plano: sugestões, receitas ou alimento.
Future<void> showAddPlanItemSheet(
  BuildContext context,
  WidgetRef ref, {
  required MealPlanSummary plan,
  required int day,
  required String mealType,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _AddItemSheet(planId: plan.id, day: day, mealType: mealType),
    ),
  );
  if (added ?? false) _refreshPlan(ref, plan.id);
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({required this.planId, required this.day, required this.mealType});

  final String planId;
  final int day;
  final String mealType;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  late final Future<PlanSuggestions> _suggestions = ref
      .read(planningRepositoryProvider)
      .suggestions(widget.planId, day: widget.day, mealType: widget.mealType);
  bool _busy = false;

  Future<void> _addRecipe(Recipe recipe) async {
    final servings = await askServings(context, recipe.title);
    if (servings == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(planningRepositoryProvider).addRecipe(
        widget.planId,
        day: widget.day,
        mealType: widget.mealType,
        recipeId: recipe.id,
        servings: servings,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showFailure(context, e);
      }
    }
  }

  Future<void> _addFood() async {
    final item = await showFoodPicker(context);
    final food = item?.food;
    if (item == null || food == null || !mounted) return;
    // O plano guarda g/ml; porções do cadastro são convertidas.
    final quantity = item.unit == 'serving' && food.servingSize != null ? item.quantity * food.servingSize! : item.quantity;
    setState(() => _busy = true);
    try {
      await ref.read(planningRepositoryProvider).addFood(
        widget.planId,
        day: widget.day,
        mealType: widget.mealType,
        foodId: food.id,
        quantity: quantity,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showFailure(context, e);
      }
    }
  }

  Future<void> _browseRecipes() async {
    final recipe = await showRecipePicker(context, mealType: widget.mealType);
    if (recipe != null && mounted) await _addRecipe(recipe);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.page),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Adicionar em ${MealTypes.label(widget.mealType)}', style: context.text.titleLarge),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _browseRecipes,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Receitas'),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _addFood,
                icon: const Icon(Icons.search),
                label: const Text('Alimento'),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Sugestões'),
        Expanded(
          child: FutureBuilder<PlanSuggestions>(
            future: _suggestions,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyState(
                  compact: true,
                  icon: Icons.cloud_off_outlined,
                  title: 'Sugestões indisponíveis',
                  message: 'Você ainda pode escolher uma receita ou um alimento.',
                );
              }
              final data = snapshot.data;
              if (data == null) return const Center(child: CircularProgressIndicator());
              if (data.recipes.isEmpty) {
                return const EmptyState(
                  compact: true,
                  icon: Icons.menu_book_outlined,
                  title: 'Sem receitas para esta refeição',
                  message: 'Escolha um alimento do banco ou veja todas as receitas.',
                );
              }
              return ListView(
                children: [
                  if (data.targetKcal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Text(
                        'Referência para esta refeição: cerca de ${Fmt.kcal(data.targetKcal!)} (o que falta para a meta do dia dividido pelas refeições ainda vazias).',
                        style: context.text.bodySmall,
                      ),
                    ),
                  for (final r in data.recipes)
                    RecipeTile(recipe: r, onTap: _busy ? null : () => _addRecipe(r)),
                  const SizedBox(height: Space.sm),
                  const AllergyNotice(),
                  const SizedBox(height: Space.lg),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Pergunta quantas porções da receita entram no plano.
Future<double?> askServings(BuildContext context, String title) {
  var servings = 1.0;
  return showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quantas porções?'),
            const SizedBox(height: Space.md),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.5, label: Text('½')),
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 1.5, label: Text('1½')),
                ButtonSegment(value: 2, label: Text('2')),
              ],
              selected: {servings},
              onSelectionChanged: (s) => setState(() => servings = s.first),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(servings), child: const Text('Adicionar')),
        ],
      ),
    ),
  );
}

/// Adiciona uma receita a um plano escolhido (cria o desta semana se preciso).
Future<void> addRecipeToPlanFlow(BuildContext context, WidgetRef ref, Recipe recipe) async {
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
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: Text('Adicionar a qual plano?', style: context.text.titleMedium),
            ),
            for (final p in plans.take(6))
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(p.title),
                subtitle: Text(weekRange(p.startsOn, p.endsOn)),
                onTap: () => Navigator.of(context).pop(p),
              ),
            if (!plans.any((p) => p.startsOn == thisWeek))
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Novo plano desta semana'),
                onTap: () => Navigator.of(context).pop('new'),
              ),
          ],
        ),
      ),
    );
    if (target == null || !context.mounted) return;
    final plan = target is MealPlanSummary ? target : await repo.createPlan(week: thisWeek);
    if (!context.mounted) return;

    final slot = await _pickSlot(context, plan, recipe);
    if (slot == null || !context.mounted) return;
    final servings = await askServings(context, recipe.title);
    if (servings == null) return;
    await repo.addRecipe(plan.id, day: slot.day, mealType: slot.mealType, recipeId: recipe.id, servings: servings);
    _refreshPlan(ref, plan.id);
    if (context.mounted) showMessage(context, 'Receita adicionada ao plano.');
  } on Object catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

Future<({int day, String mealType})?> _pickSlot(BuildContext context, MealPlanSummary plan, Recipe recipe) {
  var day = plan.contains(DateTime.now()) ? DateTime.now().weekday : 1;
  var mealType = recipe.mealTypes.isNotEmpty ? recipe.mealTypes.first : 'lunch';
  return showDialog<({int day, String mealType})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Quando?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Space.xs,
              children: [
                for (var d = 1; d <= 7; d++)
                  ChoiceChip(
                    label: Text(_weekday.format(plan.startsOn.add(Duration(days: d - 1))).replaceAll('.', '')),
                    selected: day == d,
                    onSelected: (_) => setState(() => day = d),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<String>(
              initialValue: mealType,
              decoration: const InputDecoration(labelText: 'Refeição'),
              items: [
                for (final e in MealTypes.labels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => mealType = v ?? mealType),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((day: day, mealType: mealType)),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ),
  );
}
