import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/food/presentation/food_page.dart';

class _Repository implements FoodRepository {
  final templates = <MealTemplate>[];
  int saves = 0;
  int logs = 0;

  @override
  Future<List<MealTemplate>> mealTemplates() async => List.of(templates);

  @override
  Future<MealTemplate> saveAsTemplate(String mealId, {String? name}) async {
    saves++;
    final template = MealTemplate.fromJson({
      'id': 'favorite',
      'name': name,
      'meal_type': 'lunch',
      'items': <Object>[],
      'totals': <String, Object>{},
    });
    templates.add(template);
    return template;
  }

  @override
  Future<Meal> logTemplate(
    String templateId, {
    required String requestId,
    String? mealType,
    DateTime? eatenAt,
  }) async {
    logs++;
    return _meal;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _meal = Meal.fromJson({
  'id': 'lunch',
  'title': 'Meu almoço',
  'meal_type': 'lunch',
  'eaten_at': '2026-10-19T12:00:00Z',
  'local_date': '2026-10-19',
  'source': 'manual',
  'totals': <String, Object>{},
});

Widget _app(_Repository repo) => ProviderScope(
  overrides: [
    foodRepositoryProvider.overrideWithValue(repo),
    mealsOnDayProvider.overrideWith((ref, day) async => [_meal]),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showFavoriteMealsSheet(context),
          child: const Text('Abrir favoritas'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'adiciona favorita pela própria lista sem registrar outra refeição',
    (tester) async {
      final repo = _Repository();
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Abrir favoritas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar favorita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meu almoço'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar favorita'));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.logs, 0);
      expect(find.text('Meu almoço'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      // Tocar no nome não pode adicionar uma refeição sem uma ação explícita.
      await tester.tap(find.text('Meu almoço'));
      await tester.pumpAndSettle();
      expect(repo.logs, 0);
    },
  );

  testWidgets('cancelar o diálogo de favorita não grava nada', (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.text('Abrir favoritas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher do diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meu almoço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(repo.logs, 0);
    expect(find.text('Suas favoritas começam aqui'), findsOneWidget);
  });
}
