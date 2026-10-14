import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/plan/data/plan_repository.dart';

void main() {
  test('lê rascunho incompleto do código de barras sem inventar valores', () {
    final lookup = BarcodeLookup.fromJson({
      'status': 'incomplete',
      'food': null,
      'draft': {'code': '7891000100103', 'name': 'Biscoito', 'base_unit': 'g', 'energy_kcal': 250, 'protein_g': 3, 'carbs_g': null, 'fat_g': null},
      'attribution': 'Dados do rótulo via Open Food Facts (ODbL). Confira com a embalagem.',
    });

    expect(lookup.status, 'incomplete');
    expect(lookup.food, isNull);
    expect(lookup.draft!.energyKcal, 250);
    expect(lookup.draft!.carbsG, isNull);
    expect(lookup.attribution, contains('Open Food Facts'));
  });

  test('lê produtos das lojas no plano atual', () {
    Map<String, dynamic> json(Map<String, dynamic>? store) => {
      'plan': {'code': 'free', 'name': 'Gratuito', 'features': <String>[]},
      'usage_today': <Object>[],
      'payments_available': store != null,
      'store': ?store,
    };

    final withStore = CurrentPlan.fromJson(json({
      'android': true,
      'ios': false,
      'products': [
        {'product_id': 'premium_mensal', 'plan_code': 'premium'},
      ],
      'source': null,
      'auto_renew': null,
    }));
    expect(withStore.store.android, isTrue);
    expect(withStore.store.productIds, ['premium_mensal']);

    final legacy = CurrentPlan.fromJson(json(null));
    expect(legacy.paymentsAvailable, isFalse);
    expect(legacy.store.productIds, isEmpty);
  });
}
