import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';

void main() {
  test('lê refeição favorita com totais e nomes dos itens', () {
    final t = MealTemplate.fromJson({
      'id': '01JTEMPLATE',
      'name': 'Almoço leve',
      'meal_type': 'lunch',
      'items': [
        {'food_id': 3, 'name': 'Arroz', 'quantity': 100, 'unit': 'g'},
        {'food_id': null, 'name': 'Salada', 'quantity': 1, 'unit': 'unit'},
      ],
      'totals': {'energy_kcal': 168, 'protein_g': 3.5, 'carbs_g': 34.1, 'fat_g': 1.2},
      'usage_count': 2,
      'last_used_at': null,
    });

    expect(t.itemNames, ['Arroz', 'Salada']);
    expect(t.totals.energyKcal, 168);
    expect(t.usageCount, 2);
  });

  test('alimento traz a marcação de favorito', () {
    final food = Food.fromJson({
      'id': 3,
      'name': 'Arroz',
      'source_label': 'Tabela TACO',
      'is_custom': false,
      'is_favorite': true,
      'base_unit': 'g',
      'per_100': {'energy_kcal': 128, 'protein_g': 2.5, 'carbs_g': 28.1, 'fat_g': 0.2},
    });
    expect(food.isFavorite, isTrue);
  });

  test('perfil lê alergias, alimentos a evitar e refeições planejadas', () {
    final p = Profile.fromJson({
      'allergies': ['gluten'],
      'avoid_foods': 'jiló',
      'planned_meals': ['breakfast', 'dinner'],
    });
    expect(p.allergies, ['gluten']);
    expect(p.avoidFoods, 'jiló');
    expect(p.plannedMeals, ['breakfast', 'dinner']);
    expect(Profile.fromJson(const {}).plannedMeals, ['breakfast', 'lunch', 'dinner']);
  });
}
