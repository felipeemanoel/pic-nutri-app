import '../../../core/utils/formatters.dart';

/// Tipos de refeição e seus rótulos.
abstract final class MealTypes {
  static const labels = {
    'breakfast': 'Café da manhã',
    'morning_snack': 'Lanche da manhã',
    'lunch': 'Almoço',
    'afternoon_snack': 'Lanche da tarde',
    'dinner': 'Jantar',
    'supper': 'Ceia',
    'other': 'Outro',
  };

  static String label(String type) => labels[type] ?? type;

  /// Sugestão de tipo pelo horário (o usuário pode trocar).
  static String suggestFor(DateTime time) {
    final h = time.hour;
    if (h < 10) return 'breakfast';
    if (h < 12) return 'morning_snack';
    if (h < 15) return 'lunch';
    if (h < 18) return 'afternoon_snack';
    if (h < 21) return 'dinner';
    return 'supper';
  }
}

abstract final class Units {
  static const labels = {
    'g': 'g',
    'ml': 'ml',
    'serving': 'porção',
    'unit': 'unidade',
  };
}

/// Calorias e macronutrientes (absolutos).
class Nutrients {
  const Nutrients({
    this.energyKcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) => Nutrients(
    energyKcal: toDouble(json['energy_kcal']) ?? 0,
    proteinG: toDouble(json['protein_g']) ?? 0,
    carbsG: toDouble(json['carbs_g']) ?? 0,
    fatG: toDouble(json['fat_g']) ?? 0,
  );

  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Nutrients operator +(Nutrients other) => Nutrients(
    energyKcal: energyKcal + other.energyKcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
  );

  Nutrients scale(double factor) => Nutrients(
    energyKcal: energyKcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
  );
}

/// Alimento do banco (valores por 100 g/ml).
/// Medida caseira de um alimento (ex.: "1 colher de sopa" = 15 g).
class FoodPortion {
  const FoodPortion({required this.id, required this.label, required this.grams});

  factory FoodPortion.fromJson(Map<String, dynamic> json) => FoodPortion(
    id: toInt(json['id'])!,
    label: json['label'] as String,
    grams: toDouble(json['grams'])!,
  );

  final int id;
  final String label;

  /// Equivalência na unidade-base do alimento (g ou ml).
  final double grams;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.sourceLabel,
    required this.isCustom,
    required this.baseUnit,
    required this.per100,
    this.brand,
    this.servingSize,
    this.servingLabel,
    this.isFavorite = false,
    this.categoryName,
    this.portions = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    id: toInt(json['id'])!,
    name: json['name'] as String,
    brand: json['brand'] as String?,
    sourceLabel: json['source_label'] as String? ?? '',
    isCustom: json['is_custom'] as bool? ?? false,
    baseUnit: json['base_unit'] as String? ?? 'g',
    per100: Nutrients.fromJson(json['per_100'] as Map<String, dynamic>),
    servingSize: toDouble(json['serving_size']),
    servingLabel: json['serving_label'] as String?,
    isFavorite: json['is_favorite'] as bool? ?? false,
    categoryName: (json['category'] as Map<String, dynamic>?)?['name'] as String?,
    portions: [
      for (final p in json['portions'] as List<dynamic>? ?? const [])
        FoodPortion.fromJson(p as Map<String, dynamic>),
    ],
  );

  final int id;
  final String name;
  final String? brand;
  final String sourceLabel;
  final bool isCustom;
  final String baseUnit;
  final Nutrients per100;
  final double? servingSize;
  final String? servingLabel;
  final bool isFavorite;

  /// Grupo do alimento (ex.: grupos oficiais da TACO).
  final String? categoryName;

  /// Medidas caseiras cadastradas pela equipe (convertidas para g/ml).
  final List<FoodPortion> portions;

  /// Valores para a quantidade, quando calculável (mesma regra da API).
  Nutrients? nutrientsFor(double quantity, String unit) {
    if (unit == baseUnit) return per100.scale(quantity / 100);
    if (unit == 'serving' && servingSize != null) {
      return per100.scale(quantity * servingSize! / 100);
    }
    return null;
  }
}

/// Item de uma refeição (rascunho no app ou registro salvo).
class MealItem {
  const MealItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.nutrients,
    this.foodId,
    this.source = 'manual',
    this.aiConfidence,
    this.food,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
    foodId: toInt(json['food_id']),
    name: json['name'] as String? ?? '',
    quantity: toDouble(json['quantity']) ?? 0,
    unit: json['unit'] as String? ?? 'g',
    nutrients: Nutrients.fromJson(json),
    source: json['source'] as String? ?? 'manual',
    aiConfidence: toDouble(json['ai_confidence']),
  );

  final int? foodId;
  final String name;
  final double quantity;
  final String unit;
  final Nutrients nutrients;
  final String source;
  final double? aiConfidence;

  /// Alimento de origem, quando escolhido no banco nesta sessão.
  final Food? food;

  String get quantityLabel =>
      '${Fmt.decimal(quantity)} ${Units.labels[unit] ?? unit}';

  /// Corpo enviado à API. Itens do banco em g/ml/porção são recalculados no
  /// servidor; os demais levam os valores informados.
  Map<String, Object?> toJson() => {
    'food_id': ?foodId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'energy_kcal': nutrients.energyKcal,
    'protein_g': nutrients.proteinG,
    'carbs_g': nutrients.carbsG,
    'fat_g': nutrients.fatG,
    'source': source == 'ai_estimate' ? 'ai_estimate' : 'manual',
    'ai_confidence': ?aiConfidence,
  };
}

class Meal {
  const Meal({
    required this.id,
    required this.mealType,
    required this.eatenAt,
    required this.localDate,
    required this.totals,
    required this.items,
    required this.source,
    this.title,
    this.notes,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    mealType: json['meal_type'] as String,
    title: json['title'] as String?,
    eatenAt: DateTime.parse(json['eaten_at'] as String).toLocal(),
    localDate: json['local_date'] as String,
    notes: json['notes'] as String?,
    source: json['source'] as String? ?? 'manual',
    totals: Nutrients.fromJson(json['totals'] as Map<String, dynamic>),
    items: (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(MealItem.fromJson)
        .toList(),
  );

  final String id;
  final String mealType;
  final String? title;
  final DateTime eatenAt;
  final String localDate;
  final String? notes;
  final String source;
  final Nutrients totals;
  final List<MealItem> items;

  String get displayName => title ?? MealTypes.label(mealType);
}

class NutritionSummary {
  const NutritionSummary({
    required this.mealsCount,
    required this.totals,
    required this.goalKcal,
    required this.goalProteinG,
    required this.goalCarbsG,
    required this.goalFatG,
    required this.remainingKcal,
  });

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    final goals = json['goals'] as Map<String, dynamic>? ?? const {};
    return NutritionSummary(
      mealsCount: toInt(json['meals_count']) ?? 0,
      totals: Nutrients.fromJson(json['totals'] as Map<String, dynamic>),
      goalKcal: toInt(goals['energy_kcal']),
      goalProteinG: toInt(goals['protein_g']),
      goalCarbsG: toInt(goals['carbs_g']),
      goalFatG: toInt(goals['fat_g']),
      remainingKcal: toDouble(json['energy_remaining_kcal']),
    );
  }

  final int mealsCount;
  final Nutrients totals;
  final int? goalKcal;
  final int? goalProteinG;
  final int? goalCarbsG;
  final int? goalFatG;
  final double? remainingKcal;
}

/// Refeição favorita (itens salvos para registrar de novo).
class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.name,
    required this.totals,
    required this.itemNames,
    required this.usageCount,
    this.mealType,
    this.items = const [],
  });

  factory MealTemplate.fromJson(Map<String, dynamic> json) => MealTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    mealType: json['meal_type'] as String?,
    totals: Nutrients.fromJson(json['totals'] as Map<String, dynamic>),
    itemNames: (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((i) => i['name'] as String? ?? '')
        .toList(),
    usageCount: toInt(json['usage_count']) ?? 0,
    items: (json['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(MealItem.fromJson).toList(),
  );

  final String id;
  final String name;
  final String? mealType;
  final Nutrients totals;
  final List<String> itemNames;
  final int usageCount;

  /// Alimentos e quantidades salvos (revisados antes de registrar de novo).
  final List<MealItem> items;
}

/// Resultado da busca por código de barras.
class BarcodeLookup {
  const BarcodeLookup({required this.status, this.food, this.draft, this.attribution});

  factory BarcodeLookup.fromJson(Map<String, dynamic> json) => BarcodeLookup(
    status: json['status'] as String? ?? 'not_found',
    food: json['food'] == null ? null : Food.fromJson(json['food'] as Map<String, dynamic>),
    draft: json['draft'] == null ? null : BarcodeDraft.fromJson(json['draft'] as Map<String, dynamic>),
    attribution: json['attribution'] as String?,
  );

  /// found, incomplete ou not_found.
  final String status;
  final Food? food;
  final BarcodeDraft? draft;
  final String? attribution;
}

/// Dados parciais do rótulo (Open Food Facts) para o usuário completar.
/// Valores ausentes ficam nulos: nada é estimado.
class BarcodeDraft {
  const BarcodeDraft({
    required this.code,
    required this.baseUnit,
    this.name,
    this.brand,
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory BarcodeDraft.fromJson(Map<String, dynamic> json) => BarcodeDraft(
    code: json['code'] as String? ?? '',
    baseUnit: json['base_unit'] as String? ?? 'g',
    name: json['name'] as String?,
    brand: json['brand'] as String?,
    energyKcal: toDouble(json['energy_kcal']),
    proteinG: toDouble(json['protein_g']),
    carbsG: toDouble(json['carbs_g']),
    fatG: toDouble(json['fat_g']),
  );

  final String code;
  final String baseUnit;
  final String? name;
  final String? brand;
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
}
