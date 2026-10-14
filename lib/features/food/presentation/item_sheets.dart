import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/form_fields.dart';
import '../data/nutrition_models.dart';

/// Quantidade de um alimento do banco. Valores calculados a partir dos dados
/// por 100 g/ml da fonte identificada.
Future<MealItem?> showQuantitySheet(
  BuildContext context,
  Food food, {
  MealItem? initial,
}) => showModalBottomSheet<MealItem>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _QuantitySheet(food: food, initial: initial),
);

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.food, this.initial});

  final Food food;
  final MealItem? initial;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _quantity = TextEditingController(
    text: widget.initial != null
        ? Fmt.decimal(widget.initial!.quantity)
        : '100',
  );
  late String _unit = widget.initial?.unit ?? widget.food.baseUnit;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Nutrients? get _computed {
    final q = Validators.parseNumber(_quantity.text);
    return q == null ? null : widget.food.nutrientsFor(q, _unit);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final n = _computed;
    final units = {
      food.baseUnit: food.baseUnit,
      if (food.servingSize != null)
        'serving':
            '${food.servingLabel ?? 'porção'} (${Fmt.decimal(food.servingSize!)} ${food.baseUnit})',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(food.name, style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Fonte: ${food.sourceLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _quantity,
                    label: 'Quantidade',
                    min: 0.1,
                    max: 5000,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // Recria ao escolher uma medida caseira (que volta para g/ml).
                    key: ValueKey(_unit),
                    initialValue: units.containsKey(_unit)
                        ? _unit
                        : food.baseUnit,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    isExpanded: true,
                    items: [
                      for (final e in units.entries)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            if (food.portions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Medidas caseiras', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in food.portions)
                    ActionChip(
                      label: Text('${p.label} (${Fmt.decimal(p.grams)} ${food.baseUnit})'),
                      onPressed: () => setState(() {
                        _unit = food.baseUnit;
                        _quantity.text = Fmt.decimal(p.grams);
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              n == null
                  ? 'Informe a quantidade.'
                  : '${Fmt.kcal(n.energyKcal)} · P ${Fmt.grams(n.proteinG)} · C ${Fmt.grams(n.carbsG)} · G ${Fmt.grams(n.fatG)}',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate() || n == null) return;
                Navigator.of(context).pop(
                  MealItem(
                    foodId: food.id,
                    food: food,
                    name: food.name,
                    quantity: Validators.parseNumber(_quantity.text)!,
                    unit: _unit,
                    nutrients: n,
                    source: 'food_db',
                  ),
                );
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item informado manualmente (ou correção de uma estimativa da IA).
Future<MealItem?> showManualItemSheet(
  BuildContext context, {
  MealItem? initial,
}) => showModalBottomSheet<MealItem>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ManualItemSheet(initial: initial),
);

class _ManualItemSheet extends StatefulWidget {
  const _ManualItemSheet({this.initial});

  final MealItem? initial;

  @override
  State<_ManualItemSheet> createState() => _ManualItemSheetState();
}

class _ManualItemSheetState extends State<_ManualItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _unit = 'unit';

  MealItem? get _i => widget.initial;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      _quantity.text = _fmt(initial.quantity);
      _kcal.text = _fmt(initial.nutrients.energyKcal);
      _protein.text = _fmt(initial.nutrients.proteinG);
      _carbs.text = _fmt(initial.nutrients.carbsG);
      _fat.text = _fmt(initial.nutrients.fatG);
      _unit = initial.unit == 'serving' ? 'unit' : initial.unit;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _quantity, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edited = _i != null;
    return Padding(
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
                edited ? 'Editar item' : 'Item manual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Informe os valores da porção consumida (ex.: do rótulo).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Alimento'),
                validator: (v) => Validators.required(v, 'Nome'),
                maxLength: 160,
              ),
              Row(
                children: [
                  Expanded(
                    child: NumberField(
                      controller: _quantity,
                      label: 'Quantidade',
                      min: 0.1,
                      max: 5000,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: [
                        for (final e in Units.labels.entries)
                          if (e.key != 'serving')
                            DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                      ],
                      onChanged: (v) => setState(() => _unit = v ?? _unit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _kcal,
                label: 'Calorias',
                unit: 'kcal',
                min: 0,
                max: 5000,
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
                      max: 500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      controller: _carbs,
                      label: 'Carboidratos',
                      unit: 'g',
                      min: 0,
                      max: 1000,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      controller: _fat,
                      label: 'Gorduras',
                      unit: 'g',
                      min: 0,
                      max: 500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  double n(TextEditingController c) =>
                      Validators.parseNumber(c.text) ?? 0;
                  Navigator.of(context).pop(
                    MealItem(
                      name: _name.text.trim(),
                      quantity: n(_quantity),
                      unit: _unit,
                      nutrients: Nutrients(
                        energyKcal: n(_kcal),
                        proteinG: n(_protein),
                        carbsG: n(_carbs),
                        fatG: n(_fat),
                      ),
                      // Uma estimativa da IA corrigida pelo usuário continua
                      // identificada como estimativa revisada.
                      source: _i?.source == 'ai_estimate'
                          ? 'ai_estimate'
                          : 'manual',
                      aiConfidence: _i?.aiConfidence,
                    ),
                  );
                },
                child: Text(edited ? 'Salvar item' : 'Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
