import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/planning/data/planning_models.dart';

Map<String, dynamic> _item(int id, String mealType, {String kind = 'food'}) => {
  'id': id,
  'day': 1,
  'meal_type': mealType,
  'kind': kind,
  'recipe': kind == 'recipe' ? {'id': 9, 'title': 'Arroz simples', 'servings': 2} : null,
  'food': kind == 'food' ? {'id': 3, 'name': 'Banana, prata, crua', 'base_unit': 'g'} : null,
  'quantity': kind == 'food' ? 100 : null,
  'servings': kind == 'recipe' ? 1.5 : null,
  'note': null,
  'nutrients': kind == 'removed' ? null : {'energy_kcal': 98, 'protein_g': 1.3, 'carbs_g': 26, 'fat_g': 0.1},
};

void main() {
  test('interpreta o plano com dias, itens e totais', () {
    final plan = MealPlan.fromJson({
      'id': '01JPLAN',
      'title': 'Semana de 12/10',
      'starts_on': '2026-10-12',
      'ends_on': '2026-10-18',
      'items_count': 3,
      'days': [
        {
          'day': 1,
          'date': '2026-10-12',
          'goal_kcal': 1800,
          'totals': {'energy_kcal': 196, 'protein_g': 2.6, 'carbs_g': 52, 'fat_g': 0.2},
          'items': [
            _item(1, 'dinner', kind: 'recipe'),
            _item(2, 'breakfast'),
            _item(3, 'lunch', kind: 'removed'),
          ],
        },
      ],
    });

    final day = plan.days.single;
    expect(plan.itemsCount, 3);
    expect(plan.contains(DateTime(2026, 10, 18, 22)), isTrue);
    expect(plan.contains(DateTime(2026, 10, 19)), isFalse);
    // Ordem das refeições do dia, não a ordem de cadastro.
    expect(day.byMeal.keys, ['breakfast', 'lunch', 'dinner']);
    expect(day.items.first.amountLabel, '1,5 porções');
    expect(day.items[1].amountLabel, '100 g');
    expect(day.items.last.isAvailable, isFalse);
    expect(day.items.last.nutrients, isNull);
  });

  test('lê lista de compras e sugestões', () {
    final group = ShoppingGroup.fromJson({
      'category': 'Cereais e derivados',
      'items': [
        {'food_id': 1, 'name': 'Arroz', 'quantity': 250, 'unit': 'g', 'checked': true},
      ],
    });
    expect(group.items.single.checked, isTrue);

    final suggestions = PlanSuggestions.fromJson({
      'target_kcal': 500,
      'recipes': [
        {
          'id': 4,
          'title': 'Salada',
          'summary': null,
          'prep_minutes': 10,
          'per_serving': {'energy_kcal': 120, 'protein_g': 3, 'carbs_g': 10, 'fat_g': 7},
        },
      ],
    });
    expect(suggestions.targetKcal, 500);
    expect(suggestions.recipes.single.perServing.energyKcal, 120);
  });
}
