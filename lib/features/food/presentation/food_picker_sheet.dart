import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';
import 'barcode_scanner_page.dart';
import 'item_sheets.dart';

/// Busca no banco de alimentos e devolve o item com a quantidade escolhida.
Future<MealItem?> showFoodPicker(BuildContext context) async {
  final food = await showModalBottomSheet<Food>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.9, child: _FoodSearch()),
  );
  if (food == null || !context.mounted) return null;
  return showQuantitySheet(context, food);
}

class _FoodSearch extends ConsumerStatefulWidget {
  const _FoodSearch();

  @override
  ConsumerState<_FoodSearch> createState() => _FoodSearchState();
}

class _FoodSearchState extends ConsumerState<_FoodSearch> {
  final _query = TextEditingController();
  Timer? _debounce;
  AsyncValue<List<Food>> _results = const AsyncData([]);

  /// Sem busca: 0 = recentes, 1 = favoritos.
  int _tab = 0;
  final Map<int, bool> _favorite = {};
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadTab();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  bool get _searching => _query.text.trim().isNotEmpty;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (value.trim().isEmpty) {
        _loadTab();
      } else {
        _search(value);
      }
    });
  }

  Future<void> _search(String value) async {
    setState(() => _results = const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(foodRepositoryProvider).searchFoods(value),
    );
    if (mounted && _query.text == value) setState(() => _results = result);
  }

  Future<void> _loadTab() async {
    setState(() => _results = const AsyncLoading());
    final repo = ref.read(foodRepositoryProvider);
    final tab = _tab;
    final result = await AsyncValue.guard(
      () => tab == 0 ? repo.recentFoods() : repo.favoriteFoods(),
    );
    if (mounted && !_searching && _tab == tab) setState(() => _results = result);
  }

  Future<void> _toggleFavorite(Food food) async {
    final next = !(_favorite[food.id] ?? food.isFavorite);
    setState(() => _favorite[food.id] = next);
    try {
      await ref.read(foodRepositoryProvider).setFavorite(food.id, favorite: next);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _favorite[food.id] = !next);
      showFailure(context, error);
    }
  }

  Future<void> _createFood({BarcodeDraft? draft, String? notice}) async {
    final food = await showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CustomFoodForm(initialName: draft?.name ?? _query.text, draft: draft, notice: notice),
    );
    if (food != null && mounted) Navigator.of(context).pop(food);
  }

  /// Lê o código de barras e busca o produto (cadastro da equipe ou
  /// Open Food Facts). Sem dados completos, abre o cadastro para completar.
  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final result = await ref.read(foodRepositoryProvider).lookupBarcode(code);
      if (!mounted) return;
      switch (result.status) {
        case 'found':
          if (result.attribution != null) showMessage(context, result.attribution!);
          Navigator.of(context).pop(result.food);
        case 'incomplete':
          await _createFood(
            draft: result.draft,
            notice: 'O rótulo encontrado não tem todos os valores. Complete com os dados da embalagem.',
          );
        default:
          await _createFood(notice: 'Produto não encontrado. Cadastre com os valores do rótulo da embalagem.');
      }
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Column(
        children: [
          TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar alimento',
              suffixIcon: _scanning
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      tooltip: 'Ler código de barras',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
            ),
            onChanged: _onChanged,
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              if (!_searching)
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Recentes'), icon: Icon(Icons.history, size: 18)),
                    ButtonSegment(value: 1, label: Text('Favoritos'), icon: Icon(Icons.star_outline, size: 18)),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) {
                    setState(() => _tab = v.first);
                    _loadTab();
                  },
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _createFood,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar'),
              ),
            ],
          ),
          Expanded(
            child: AsyncValueView<List<Food>>(
              value: _results,
              onRetry: () => _searching ? _search(_query.text) : _loadTab(),
              data: (foods) => foods.isEmpty
                  ? EmptyState(
                      icon: _searching ? Icons.search_off : (_tab == 0 ? Icons.history : Icons.star_outline),
                      title: _searching
                          ? 'Nenhum alimento encontrado'
                          : _tab == 0
                          ? 'Nenhum alimento recente'
                          : 'Nenhum favorito',
                      message: _searching
                          ? 'Cadastre o alimento com os valores do rótulo ou use um item manual.'
                          : _tab == 0
                          ? 'Os alimentos que você registrar aparecem aqui para facilitar.'
                          : 'Toque na estrela de um alimento para salvá-lo aqui.',
                    )
                  : ListView.separated(
                      itemCount: foods.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final f = foods[index];
                        final fav = _favorite[f.id] ?? f.isFavorite;
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: Space.xs),
                          title: Text(f.name),
                          subtitle: Text(
                            '${Fmt.kcal(f.per100.energyKcal)} por 100 ${f.baseUnit} · ${f.sourceLabel}',
                          ),
                          trailing: IconButton(
                            tooltip: fav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                            icon: Icon(
                              fav ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: fav ? context.pic.warning : null,
                            ),
                            onPressed: () => _toggleFavorite(f),
                          ),
                          onTap: () => Navigator.of(context).pop(f),
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

class _CustomFoodForm extends ConsumerStatefulWidget {
  const _CustomFoodForm({required this.initialName, this.draft, this.notice});

  final String initialName;

  /// Dados parciais do rótulo (código de barras) para completar.
  final BarcodeDraft? draft;
  final String? notice;

  @override
  ConsumerState<_CustomFoodForm> createState() => _CustomFoodFormState();
}

class _CustomFoodFormState extends ConsumerState<_CustomFoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _kcal = TextEditingController(text: _initial(widget.draft?.energyKcal));
  late final _protein = TextEditingController(text: _initial(widget.draft?.proteinG));
  late final _carbs = TextEditingController(text: _initial(widget.draft?.carbsG));
  late final _fat = TextEditingController(text: _initial(widget.draft?.fatG));
  late String _unit = widget.draft?.baseUnit ?? 'g';

  static String _initial(double? value) => value == null ? '' : Fmt.decimal(value);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    double n(TextEditingController c) => Validators.parseNumber(c.text) ?? 0;
    try {
      final food = await ref
          .read(foodRepositoryProvider)
          .createFood(
            name: _name.text,
            brand: widget.draft?.brand,
            baseUnit: _unit,
            per100: Nutrients(
              energyKcal: n(_kcal),
              proteinG: n(_protein),
              carbsG: n(_carbs),
              fatG: n(_fat),
            ),
          );
      if (mounted) Navigator.of(context).pop(food);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastrar alimento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Valores por 100 g ou 100 ml, como no rótulo. Fica visível só para você.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.notice != null) ...[
              const SizedBox(height: 12),
              StatusBanner(tone: BannerTone.warning, message: widget.notice!),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'g', label: Text('Por 100 g')),
                ButtonSegment(value: 'ml', label: Text('Por 100 ml')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _kcal,
              label: 'Calorias',
              unit: 'kcal',
              min: 0,
              max: 900,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _protein,
                    label: 'Proteínas',
                    unit: 'g',
                    min: 0,
                    max: 100,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    controller: _carbs,
                    label: 'Carboidratos',
                    unit: 'g',
                    min: 0,
                    max: 100,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    controller: _fat,
                    label: 'Gorduras',
                    unit: 'g',
                    min: 0,
                    max: 100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LoadingButton(
              label: 'Salvar alimento',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
}
