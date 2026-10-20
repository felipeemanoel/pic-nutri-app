import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'nutrition_models.dart';

/// Refeições, resumo diário e banco de alimentos.
class FoodRepository {
  const FoodRepository(this._dio);

  final Dio _dio;

  Future<List<Meal>> mealsOn(DateTime day) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'meals',
        queryParameters: {'date': Fmt.apiDate(day)},
      ),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Meal.fromJson)
        .toList();
  }

  /// Refeições dos últimos [days] dias (mais recentes primeiro), sem repetir
  /// refeições com os mesmos alimentos e quantidades.
  Future<List<Meal>> recentMeals({int days = 14, int limit = 20}) async {
    final today = DateTime.now();
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'meals',
        queryParameters: {
          'from': Fmt.apiDate(today.subtract(Duration(days: days - 1))),
          'to': Fmt.apiDate(today),
        },
      ),
    );
    final meals = (response.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(Meal.fromJson);
    final seen = <String>{};
    return [
      for (final meal in meals)
        if (meal.items.isNotEmpty && seen.add(meal.items.map((i) => '${i.name}|${i.quantity}|${i.unit}').join(';'))) meal,
    ].take(limit).toList();
  }

  Future<NutritionSummary> summaryOn(DateTime day) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'nutrition/summary',
        queryParameters: {'date': Fmt.apiDate(day)},
      ),
    );
    return NutritionSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<Meal> saveMeal({
    String? id,
    required String mealType,
    required DateTime eatenAt,
    required List<MealItem> items,
    String? title,
    String? notes,
    String? requestId,
    String? photoAnalysisId,
  }) async {
    final body = {
      'meal_type': mealType,
      'eaten_at': eatenAt.toUtc().toIso8601String(),
      'title': (title?.trim().isEmpty ?? true) ? null : title!.trim(),
      'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      'items': items.map((i) => i.toJson()).toList(),
      'client_request_id': ?requestId,
    };
    // Refeição vinda da análise por foto: confirmada pelo endpoint da análise.
    final path = photoAnalysisId != null && id == null
        ? 'ai/meal-analyses/$photoAnalysisId/confirm'
        : null;
    final response = await guard(
      () => path != null
          ? _dio.post<Map<String, dynamic>>(path, data: body)
          : id == null
          ? _dio.post<Map<String, dynamic>>('meals', data: body)
          : _dio.put<Map<String, dynamic>>('meals/$id', data: body),
    );
    return Meal.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMeal(String id) =>
      guard(() => _dio.delete<void>('meals/$id'));

  Future<List<Food>> searchFoods(String query) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'foods',
        queryParameters: {'q': query.trim()},
      ),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Food.fromJson)
        .toList();
  }

  Future<List<Food>> recentFoods() => _foodList('foods/recent');

  Future<List<Food>> favoriteFoods() => _foodList('foods/favorites');

  Future<void> setFavorite(int foodId, {required bool favorite}) => guard(
    () => favorite
        ? _dio.post<void>('foods/$foodId/favorite')
        : _dio.delete<void>('foods/$foodId/favorite'),
  );

  Future<List<Food>> _foodList(String path) async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>(path));
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Food.fromJson)
        .toList();
  }

  /// Refeições favoritas.
  Future<List<MealTemplate>> mealTemplates() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('meal-templates'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MealTemplate.fromJson)
        .toList();
  }

  Future<MealTemplate> saveAsTemplate(String mealId, {String? name}) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'meals/$mealId/favorite',
        data: {'name': (name?.trim().isEmpty ?? true) ? null : name!.trim()},
      ),
    );
    return MealTemplate.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Meal> logTemplate(
    String templateId, {
    required String requestId,
    String? mealType,
    DateTime? eatenAt,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'meal-templates/$templateId/log',
        data: {
          'client_request_id': requestId,
          'meal_type': ?mealType,
          'eaten_at': ?eatenAt?.toUtc().toIso8601String(),
        },
      ),
    );
    return Meal.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTemplate(String id) =>
      guard(() => _dio.delete<void>('meal-templates/$id'));

  /// Busca pelo código de barras (cadastro da equipe ou Open Food Facts).
  Future<BarcodeLookup> lookupBarcode(String code) async {
    final response = await guard(() => _dio.get<Map<String, dynamic>>('foods/barcode/$code'));
    return BarcodeLookup.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Food> createFood({
    required String name,
    required String baseUnit,
    required Nutrients per100,
    String? brand,
    double? servingSize,
    String? servingLabel,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'foods',
        data: {
          'name': name.trim(),
          'brand': brand,
          'base_unit': baseUnit,
          'energy_kcal': per100.energyKcal,
          'protein_g': per100.proteinG,
          'carbs_g': per100.carbsG,
          'fat_g': per100.fatG,
          'serving_size': servingSize,
          'serving_label': servingLabel,
        },
      ),
    );
    return Food.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(dioProvider)),
);

final mealTemplatesProvider = FutureProvider<List<MealTemplate>>(
  (ref) => ref.watch(foodRepositoryProvider).mealTemplates(),
);

final mealsOnDayProvider = FutureProvider.family<List<Meal>, DateTime>(
  (ref, day) => ref.watch(foodRepositoryProvider).mealsOn(day),
);

final nutritionSummaryProvider =
    FutureProvider.family<NutritionSummary, DateTime>(
      (ref, day) => ref.watch(foodRepositoryProvider).summaryOn(day),
    );

final recentMealsProvider = FutureProvider.autoDispose<List<Meal>>(
  (ref) => ref.watch(foodRepositoryProvider).recentMeals(),
);
