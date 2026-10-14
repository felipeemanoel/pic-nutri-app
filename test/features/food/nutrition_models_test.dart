import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';

void main() {
  const rice = Food(
    id: 3,
    name: 'Arroz, tipo 1, cozido',
    sourceLabel: 'Tabela TACO (NEPA/UNICAMP)',
    isCustom: false,
    baseUnit: 'g',
    per100: Nutrients(energyKcal: 128, proteinG: 2.5, carbsG: 28.1, fatG: 0.2),
    servingSize: 150,
    servingLabel: '1 escumadeira',
  );

  test('calcula valores por grama e por porção, como a API', () {
    expect(rice.nutrientsFor(200, 'g')!.energyKcal, closeTo(256, 0.001));
    expect(rice.nutrientsFor(1, 'serving')!.energyKcal, closeTo(192, 0.001));
    expect(rice.nutrientsFor(1, 'unit'), isNull);
  });

  test('item do banco envia food_id; item manual não', () {
    final fromDb = MealItem(
      foodId: rice.id,
      name: rice.name,
      quantity: 100,
      unit: 'g',
      nutrients: rice.nutrientsFor(100, 'g')!,
      source: 'food_db',
    );
    const manual = MealItem(
      name: 'Bolo',
      quantity: 1,
      unit: 'unit',
      nutrients: Nutrients(energyKcal: 300),
    );

    expect(fromDb.toJson()['food_id'], 3);
    expect(fromDb.toJson()['source'], 'manual');
    expect(manual.toJson().containsKey('food_id'), isFalse);
  });

  test('estimativa da IA mantém a origem e a confiança ao ser enviada', () {
    const ai = MealItem(
      name: 'Feijão',
      quantity: 120,
      unit: 'g',
      nutrients: Nutrients(energyKcal: 90),
      source: 'ai_estimate',
      aiConfidence: 0.6,
    );

    expect(ai.toJson()['source'], 'ai_estimate');
    expect(ai.toJson()['ai_confidence'], 0.6);
  });

  test('lê refeição da API com itens e totais', () {
    final meal = Meal.fromJson({
      'id': '01J',
      'meal_type': 'lunch',
      'title': null,
      'eaten_at': '2026-10-13T15:30:00+00:00',
      'local_date': '2026-10-13',
      'source': 'manual',
      'totals': {
        'energy_kcal': 498,
        'protein_g': 9.75,
        'carbs_g': 106.35,
        'fat_g': 1.7,
      },
      'items': [
        {
          'food_id': 3,
          'name': 'Arroz',
          'quantity': 200,
          'unit': 'g',
          'energy_kcal': 256,
          'protein_g': 5,
          'carbs_g': 56.2,
          'fat_g': 0.4,
          'source': 'food_db',
        },
      ],
    });

    expect(meal.displayName, 'Almoço');
    expect(meal.items.single.quantityLabel, '200 g');
    expect(meal.totals.carbsG, 106.35);
  });
}
