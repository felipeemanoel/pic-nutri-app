import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import 'planning_models.dart';

typedef RecipeQuery = ({String? search, String? mealType});

class PlanningRepository {
  const PlanningRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _data(Response<Map<String, dynamic>> r) =>
      r.data!['data'] as Map<String, dynamic>;

  List<Map<String, dynamic>> _items(Response<Map<String, dynamic>> r) =>
      (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();

  // Receitas

  Future<List<Recipe>> recipes(RecipeQuery q) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'recipes',
        queryParameters: {
          if (q.search != null && q.search!.isNotEmpty) 'q': q.search,
          'meal_type': ?q.mealType,
        },
      ),
    );
    return _items(r).map(Recipe.fromJson).toList();
  }

  Future<Recipe> recipe(int id) async =>
      Recipe.fromJson(_data(await guard(() => _dio.get<Map<String, dynamic>>('recipes/$id'))));

  // Planos

  Future<List<MealPlanSummary>> plans() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('meal-plans'));
    return _items(r).map(MealPlanSummary.fromJson).toList();
  }

  Future<MealPlan> createPlan({required DateTime week, String? title, String? copyFrom}) async =>
      MealPlan.fromJson(
        _data(
          await guard(
            () => _dio.post<Map<String, dynamic>>(
              'meal-plans',
              data: {
                'starts_on': Fmt.apiDate(week),
                'title': ?title,
                'copy_from': ?copyFrom,
              },
            ),
          ),
        ),
      );

  Future<MealPlan> plan(String id) async =>
      MealPlan.fromJson(_data(await guard(() => _dio.get<Map<String, dynamic>>('meal-plans/$id'))));

  Future<void> renamePlan(String id, String title) =>
      guard(() => _dio.patch<void>('meal-plans/$id', data: {'title': title}));

  Future<void> deletePlan(String id) => guard(() => _dio.delete<void>('meal-plans/$id'));

  Future<void> addRecipe(String planId, {required int day, required String mealType, required int recipeId, double servings = 1}) =>
      guard(
        () => _dio.post<void>(
          'meal-plans/$planId/items',
          data: {'day': day, 'meal_type': mealType, 'recipe_id': recipeId, 'servings': servings},
        ),
      );

  Future<void> addFood(String planId, {required int day, required String mealType, required int foodId, required double quantity}) =>
      guard(
        () => _dio.post<void>(
          'meal-plans/$planId/items',
          data: {'day': day, 'meal_type': mealType, 'food_id': foodId, 'quantity': quantity},
        ),
      );

  Future<void> removeItem(String planId, int itemId) =>
      guard(() => _dio.delete<void>('meal-plans/$planId/items/$itemId'));

  /// Registra o item no diário (mesmos cálculos do registro manual).
  Future<void> logItem(String planId, int itemId, {String? requestId}) => guard(
    () => _dio.post<void>(
      'meal-plans/$planId/items/$itemId/log',
      data: {
        'eaten_at': DateTime.now().toUtc().toIso8601String(),
        'client_request_id': requestId ?? newRequestId(),
      },
    ),
  );

  Future<PlanSuggestions> suggestions(String planId, {required int day, required String mealType}) async =>
      PlanSuggestions.fromJson(
        _data(
          await guard(
            () => _dio.get<Map<String, dynamic>>(
              'meal-plans/$planId/suggestions',
              queryParameters: {'day': day, 'meal_type': mealType},
            ),
          ),
        ),
      );

  Future<List<ShoppingGroup>> shoppingList(String planId) async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('meal-plans/$planId/shopping-list'));
    return _items(r).map(ShoppingGroup.fromJson).toList();
  }

  Future<List<ShoppingGroup>> setChecked(String planId, Set<int> foodIds) async {
    final r = await guard(
      () => _dio.put<Map<String, dynamic>>(
        'meal-plans/$planId/shopping-list',
        data: {'checked': foodIds.toList()},
      ),
    );
    return _items(r).map(ShoppingGroup.fromJson).toList();
  }
}

final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => PlanningRepository(ref.watch(dioProvider)),
);

final recipesProvider = FutureProvider.family<List<Recipe>, RecipeQuery>(
  (ref, q) => ref.watch(planningRepositoryProvider).recipes(q),
);

final recipeProvider = FutureProvider.family<Recipe, int>(
  (ref, id) => ref.watch(planningRepositoryProvider).recipe(id),
);

final mealPlansProvider = FutureProvider<List<MealPlanSummary>>(
  (ref) => ref.watch(planningRepositoryProvider).plans(),
);

final mealPlanProvider = FutureProvider.family<MealPlan, String>(
  (ref, id) => ref.watch(planningRepositoryProvider).plan(id),
);

final shoppingListProvider = FutureProvider.family<List<ShoppingGroup>, String>(
  (ref, id) => ref.watch(planningRepositoryProvider).shoppingList(id),
);
