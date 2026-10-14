import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/reports/data/report_models.dart';

void main() {
  test('lê o relatório do período com metas e comparação', () {
    final r = PeriodReport.fromJson({
      'period': 'week',
      'from': '2026-10-12',
      'to': '2026-10-18',
      'days_elapsed': 3,
      'goals': {'energy_kcal': 2000, 'protein_g': 100, 'water_ml': 2000},
      'summary': {
        'days_logged': 2,
        'avg_energy_kcal': 2225,
        'avg_protein_g': 67.5,
        'avg_carbs_g': 10,
        'avg_fat_g': 5,
        'avg_water_ml': 2000,
        'days_calories_met': 1,
        'days_protein_met': 1,
        'days_water_met': 1,
      },
      'previous': {'days_logged': 1, 'avg_energy_kcal': 1000, 'days_calories_met': 0, 'days_protein_met': 0, 'days_water_met': 0},
      'weight': null,
      'meals_by_type': [
        {'meal_type': 'lunch', 'label': 'Almoço', 'count': 2},
      ],
      'days': [
        {'date': '2026-10-12', 'meals': 1, 'energy_kcal': 1950, 'protein_g': 95, 'water_ml': 2000, 'logged': true, 'calories_met': true, 'protein_met': true, 'water_met': true},
        {'date': '2026-10-14', 'meals': 0, 'energy_kcal': 0, 'protein_g': 0, 'water_ml': 0, 'logged': false, 'calories_met': null, 'protein_met': null, 'water_met': false},
      ],
    });

    expect(r.summary.avgEnergyKcal, 2225);
    expect(r.previous.avgEnergyKcal, 1000);
    expect(r.previous.avgWaterMl, isNull);
    expect(r.days.last.caloriesMet, isNull);
    expect(r.mealsByType.single, ('Almoço', 2));
    expect(r.weightChangeKg, isNull);
  });
}
