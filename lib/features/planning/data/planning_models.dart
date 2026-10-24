import '../../../core/utils/formatters.dart';
import '../../food/data/nutrition_models.dart';

List<Map<String, dynamic>> _list(Object? v) =>
    (v as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

/// Receita publicada pela equipe; valores calculados do banco de alimentos.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.servings,
    required this.mealTypes,
    required this.perServing,
    required this.ingredients,
    this.summary,
    this.prepMinutes,
    this.tags = const [],
    this.instructions,
    this.imageUrl,
    this.author,
    this.source,
    this.updatedAt,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: toInt(json['id'])!,
    title: json['title'] as String,
    summary: json['summary'] as String?,
    servings: toInt(json['servings']) ?? 1,
    prepMinutes: toInt(json['prep_minutes']),
    mealTypes: (json['meal_types'] as List<dynamic>? ?? const []).cast<String>(),
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    perServing: Nutrients.fromJson(json['per_serving'] as Map<String, dynamic>),
    instructions: json['instructions'] as String?,
    ingredients: _list(json['ingredients']).map(RecipeIngredient.fromJson).toList(),
    imageUrl: json['image_url'] as String?,
    author: json['author'] as String?,
    source: json['source'] as String?,
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')?.toLocal(),
    isFavorite: json['is_favorite'] as bool? ?? false,
  );

  final int id;
  final String title;
  final String? summary;
  final int servings;
  final int? prepMinutes;
  final List<String> mealTypes;
  final List<String> tags;
  final Nutrients perServing;

  /// Só vem no detalhe da receita.
  final String? instructions;
  final List<RecipeIngredient> ingredients;

  /// Foto do prato (sem foto, o app mostra uma ilustração identificada como tal).
  final String? imageUrl;
  final String? author;
  final String? source;
  final DateTime? updatedAt;
  final bool isFavorite;

  Recipe copyWith({bool? isFavorite}) => Recipe(
    id: id,
    title: title,
    servings: servings,
    mealTypes: mealTypes,
    perServing: perServing,
    ingredients: ingredients,
    summary: summary,
    prepMinutes: prepMinutes,
    tags: tags,
    instructions: instructions,
    imageUrl: imageUrl,
    author: author,
    source: source,
    updatedAt: updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  /// Itens para registrar o consumo de [eaten] porções (revisados antes de salvar).
  /// Alimentos do banco levam o `food_id`: o servidor recalcula os valores.
  List<MealItem> itemsFor(double eaten) {
    final factor = eaten / (servings <= 0 ? 1 : servings);
    return [
      for (final i in ingredients)
        MealItem(
          foodId: i.foodId,
          name: i.name,
          quantity: double.parse((i.quantity * factor).toStringAsFixed(1)),
          unit: i.unit,
          nutrients: Nutrients(
            energyKcal: i.nutrients.energyKcal * factor,
            proteinG: i.nutrients.proteinG * factor,
            carbsG: i.nutrients.carbsG * factor,
            fatG: i.nutrients.fatG * factor,
          ),
        ),
    ];
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.display,
    this.source,
    this.nutrients = const Nutrients(),
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
    foodId: toInt(json['food_id'])!,
    name: json['name'] as String,
    quantity: toDouble(json['quantity']) ?? 0,
    unit: json['unit'] as String? ?? 'g',
    display: json['display'] as String?,
    source: json['source'] as String?,
    nutrients: Nutrients.fromJson(json),
  );

  final int foodId;
  final String name;
  final double quantity;
  final String unit;
  final String? display;
  final String? source;

  /// Valores da quantidade usada na receita inteira.
  final Nutrients nutrients;

  String get amountLabel {
    final base = '${Fmt.decimal(quantity)} $unit';
    return display == null || display!.isEmpty ? base : '$display ($base)';
  }
}

/// Resumo de um plano semanal (lista de planos).
class MealPlanSummary {
  const MealPlanSummary({
    required this.id,
    required this.title,
    required this.startsOn,
    required this.endsOn,
    required this.itemsCount,
  });

  factory MealPlanSummary.fromJson(Map<String, dynamic> json) => MealPlanSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    startsOn: DateTime.parse(json['starts_on'] as String),
    endsOn: DateTime.parse(json['ends_on'] as String),
    itemsCount: toInt(json['items_count']) ?? 0,
  );

  final String id;
  final String title;
  final DateTime startsOn;
  final DateTime endsOn;
  final int itemsCount;

  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startsOn) && !d.isAfter(endsOn);
  }
}

class MealPlan extends MealPlanSummary {
  const MealPlan({
    required super.id,
    required super.title,
    required super.startsOn,
    required super.endsOn,
    required super.itemsCount,
    required this.days,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final summary = MealPlanSummary.fromJson(json);
    final days = _list(json['days']).map(PlanDay.fromJson).toList();
    return MealPlan(
      id: summary.id,
      title: summary.title,
      startsOn: summary.startsOn,
      endsOn: summary.endsOn,
      itemsCount: days.fold(0, (sum, d) => sum + d.items.length),
      days: days,
    );
  }

  final List<PlanDay> days;
}

class PlanDay {
  const PlanDay({
    required this.day,
    required this.date,
    required this.totals,
    required this.items,
    this.goalKcal,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
    day: toInt(json['day'])!,
    date: DateTime.parse(json['date'] as String),
    goalKcal: toInt(json['goal_kcal']),
    totals: Nutrients.fromJson(json['totals'] as Map<String, dynamic>),
    items: _list(json['items']).map(PlanItem.fromJson).toList(),
  );

  /// 1 = segunda ... 7 = domingo.
  final int day;
  final DateTime date;
  final int? goalKcal;
  final Nutrients totals;
  final List<PlanItem> items;

  /// Itens agrupados pela ordem das refeições.
  Map<String, List<PlanItem>> get byMeal {
    final result = <String, List<PlanItem>>{};
    for (final type in MealTypes.labels.keys) {
      final items = this.items.where((i) => i.mealType == type).toList();
      if (items.isNotEmpty) result[type] = items;
    }
    return result;
  }
}

class PlanItem {
  const PlanItem({
    required this.id,
    required this.day,
    required this.mealType,
    required this.kind,
    this.recipeId,
    this.recipeTitle,
    this.foodId,
    this.foodName,
    this.baseUnit,
    this.quantity,
    this.servings,
    this.note,
    this.nutrients,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'] as Map<String, dynamic>?;
    final food = json['food'] as Map<String, dynamic>?;
    final n = json['nutrients'] as Map<String, dynamic>?;
    return PlanItem(
      id: toInt(json['id'])!,
      day: toInt(json['day'])!,
      mealType: json['meal_type'] as String,
      kind: json['kind'] as String? ?? 'removed',
      recipeId: toInt(recipe?['id']),
      recipeTitle: recipe?['title'] as String?,
      foodId: toInt(food?['id']),
      foodName: food?['name'] as String?,
      baseUnit: food?['base_unit'] as String?,
      quantity: toDouble(json['quantity']),
      servings: toDouble(json['servings']),
      note: json['note'] as String?,
      nutrients: n == null ? null : Nutrients.fromJson(n),
    );
  }

  final int id;
  final int day;
  final String mealType;

  /// recipe, food ou removed (receita/alimento retirado do banco).
  final String kind;
  final int? recipeId;
  final String? recipeTitle;
  final int? foodId;
  final String? foodName;
  final String? baseUnit;
  final double? quantity;
  final double? servings;
  final String? note;
  final Nutrients? nutrients;

  bool get isAvailable => kind != 'removed';

  String get title => recipeTitle ?? foodName ?? 'Item indisponível';

  String get amountLabel => switch (kind) {
    'recipe' => servings == 1 ? '1 porção' : '${Fmt.decimal(servings ?? 1)} porções',
    'food' => '${Fmt.decimal(quantity ?? 0)} ${baseUnit ?? 'g'}',
    _ => 'Removido do banco de alimentos',
  };
}

/// Receita adicionada só à lista de compras (sem planejar a refeição).
class ShoppingExtraRecipe {
  const ShoppingExtraRecipe({required this.recipeId, required this.title, required this.servings});

  factory ShoppingExtraRecipe.fromJson(Map<String, dynamic> json) => ShoppingExtraRecipe(
    recipeId: toInt(json['recipe_id'])!,
    title: json['title'] as String? ?? '',
    servings: toDouble(json['servings']) ?? 1,
  );

  final int recipeId;
  final String title;
  final double servings;
}

class ShoppingGroup {
  const ShoppingGroup({required this.category, required this.items});

  factory ShoppingGroup.fromJson(Map<String, dynamic> json) => ShoppingGroup(
    category: json['category'] as String,
    items: _list(json['items']).map(ShoppingItem.fromJson).toList(),
  );

  final String category;
  final List<ShoppingItem> items;
}

class ShoppingItem {
  const ShoppingItem({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    foodId: toInt(json['food_id'])!,
    name: json['name'] as String,
    quantity: toDouble(json['quantity']) ?? 0,
    unit: json['unit'] as String? ?? 'g',
    checked: json['checked'] as bool? ?? false,
  );

  final int foodId;
  final String name;
  final double quantity;
  final String unit;
  final bool checked;
}

class PlanSuggestions {
  const PlanSuggestions({required this.recipes, this.targetKcal});

  factory PlanSuggestions.fromJson(Map<String, dynamic> json) => PlanSuggestions(
    targetKcal: toDouble(json['target_kcal']),
    recipes: _list(json['recipes']).map(
      (r) => Recipe.fromJson({...r, 'servings': 1, 'meal_types': const <String>[]}),
    ).toList(),
  );

  /// Referência de calorias para a refeição (o que falta para a meta do dia
  /// dividido pelas refeições vazias); nula sem meta definida.
  final double? targetKcal;
  final List<Recipe> recipes;
}
