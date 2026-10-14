import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';

void main() {
  test('lê grupo e medidas caseiras do alimento', () {
    final food = Food.fromJson({
      'id': 1,
      'name': 'Arroz, integral, cozido',
      'source_label': 'TACO',
      'base_unit': 'g',
      'per_100': {'energy_kcal': 124, 'protein_g': 2.6, 'carbs_g': 25.8, 'fat_g': 1.0},
      'category': {'id': 1, 'name': 'Cereais e derivados'},
      'portions': [
        {'id': 3, 'label': '1 colher de sopa', 'grams': 25},
      ],
    });

    expect(food.categoryName, 'Cereais e derivados');
    expect(food.portions.single.grams, 25);
    // A medida caseira vira gramas: valores continuam vindo da tabela.
    expect(food.nutrientsFor(food.portions.single.grams, 'g')!.energyKcal, closeTo(31, 0.01));
  });

  test('aceita alimento sem grupo nem porções', () {
    final food = Food.fromJson({
      'id': 2,
      'name': 'Meu bolo',
      'base_unit': 'g',
      'per_100': {'energy_kcal': 300, 'protein_g': 5, 'carbs_g': 50, 'fat_g': 10},
    });
    expect(food.categoryName, isNull);
    expect(food.portions, isEmpty);
  });
}
