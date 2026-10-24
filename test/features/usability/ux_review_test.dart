import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picnutri/features/ai/presentation/meal_photo_page.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/presentation/home_page.dart';
import 'package:picnutri/features/planning/data/planning_models.dart';
import 'package:picnutri/features/planning/data/planning_repository.dart';
import 'package:picnutri/features/planning/presentation/recipe_widgets.dart';
import 'package:picnutri/features/planning/presentation/recipes_page.dart';

import '../../helpers/fakes.dart';

Recipe _recipe({String? image, bool favorite = false}) => Recipe.fromJson({
  'id': 7,
  'title': 'Frango com arroz',
  'servings': 4,
  'prep_minutes': 30,
  'meal_types': ['lunch'],
  'tags': <String>[],
  'per_serving': {
    'energy_kcal': 400,
    'protein_g': 30,
    'carbs_g': 40,
    'fat_g': 10,
  },
  'instructions': 'Preparar.',
  'ingredients': [
    {
      'food_id': 1,
      'name': 'Frango',
      'quantity': 400,
      'unit': 'g',
      'energy_kcal': 640,
      'protein_g': 120,
      'carbs_g': 0,
      'fat_g': 16,
    },
    {
      'food_id': 2,
      'name': 'Arroz',
      'quantity': 300,
      'unit': 'g',
      'energy_kcal': 390,
      'protein_g': 8,
      'carbs_g': 84,
      'fat_g': 1,
    },
  ],
  'image_url': image,
  'author': 'Equipe PicNutri',
  'source': 'Receita da casa',
  'updated_at': '2026-10-18T10:00:00Z',
  'is_favorite': favorite,
});

Dashboard _dash({
  int water = 0,
  int waterGoal = 2000,
  double protein = 0,
  int? proteinGoal = 90,
  int meals = 1,
}) => Dashboard.fromJson({
  'date': '2026-10-20',
  'is_today': true,
  'nutrition': {
    'meals_count': meals,
    'totals': {
      'energy_kcal': 900,
      'protein_g': protein,
      'carbs_g': 0,
      'fat_g': 0,
    },
    'goals': {
      'energy_kcal': 1800,
      'protein_g': proteinGoal,
      'carbs_g': null,
      'fat_g': null,
    },
    'energy_remaining_kcal': 900,
  },
  'water': {'total_ml': water, 'goal_ml': waterGoal},
  'weight': null,
  'goal': null,
  'medication_tracking_enabled': false,
});

void main() {
  group('Início: próximo passo sem repetir os cartões', () {
    test('aponta só o que falta, na ordem água, proteínas, metas', () {
      expect(homeNextStep(_dash(water: 500)).title, 'Faltam 1.500 ml de água');
      expect(
        homeNextStep(_dash(water: 2000, protein: 50)).action,
        'Ver receitas',
      );
      expect(
        homeNextStep(_dash(water: 2000, proteinGoal: null)).action,
        'Definir metas',
      );
      final done = homeNextStep(_dash(water: 2000, protein: 95));
      expect(done.action, isNull);
      expect(done.title, contains('alcançadas'));
    });

    test('critério de proteína é 100% da meta, igual ao relatório', () {
      expect(
        homeNextStep(_dash(water: 2000, protein: 89)).action,
        'Ver receitas',
      );
      expect(homeNextStep(_dash(water: 2000, protein: 90)).action, isNull);
    });
  });

  group('Receitas', () {
    test(
      '"Comi esta receita" escala ingredientes pelas porções e mantém o food_id',
      () {
        final items = _recipe().itemsFor(1); // receita rende 4
        expect(items.map((i) => i.quantity), [100, 75]);
        expect(items.first.foodId, 1);
        expect(items.first.nutrients.proteinG, 30);
      },
    );

    testWidgets('sem foto, a capa é uma ilustração identificada como tal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: RecipeCard(recipe: _recipe(), onTap: () {}),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Ilustração'), findsOneWidget);
      expect(find.text('30 min · 4 porções · 400 kcal/porção'), findsOneWidget);
    });

    testWidgets(
      'detalhe separa registrar, planejar e lista de compras, com autoria e aviso',
      (tester) async {
        tester.view
          ..physicalSize = const Size(400, 2000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Object? extra;
        final router = GoRouter(
          initialLocation: '/r',
          routes: [
            GoRoute(
              path: '/r',
              builder: (_, _) => const RecipePage(recipeId: 7),
            ),
            GoRoute(
              path: '/food/meal-from-recipe',
              builder: (_, state) {
                extra = state.extra;
                return const Scaffold(body: Text('revisão'));
              },
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...sessionOverrides(SessionSignedIn(testAccount())),
              recipeProvider.overrideWith((ref, id) async => _recipe()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Comi esta receita'), findsOneWidget);
        expect(find.text('Planejar'), findsOneWidget);
        expect(find.text('Lista de compras'), findsOneWidget);
        expect(find.text('Por Equipe PicNutri'), findsOneWidget);
        expect(find.text('Fonte: Receita da casa'), findsOneWidget);
        expect(
          find.textContaining('não é um plano feito por um profissional'),
          findsOneWidget,
        );

        await tester.tap(find.text('Comi esta receita'));
        await tester.pumpAndSettle();
        expect(find.text('Quantas porções você comeu?'), findsOneWidget);
        await tester.tap(find.text('2'));
        await tester.tap(find.text('Revisar'));
        await tester.pumpAndSettle();

        expect(
          find.text('revisão'),
          findsOneWidget,
          reason: 'abre a revisão; nada é gravado ainda',
        );
        final draft = extra! as RecipeMealDraft;
        expect(draft.title, 'Frango com arroz');
        expect(draft.items.map((i) => i.quantity), [200, 150]);
      },
    );
  });

  testWidgets('IA mostra a etapa atual para leitores de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AiSteps(current: 1))),
    );
    expect(find.bySemanticsLabel('Etapa 2 de 4: Análise'), findsOneWidget);
    handle.dispose();
  });

  test(
    'favorita traz alimentos e quantidades para revisar antes de registrar',
    () {
      final t = MealTemplate.fromJson({
        'id': 'f1',
        'name': 'Café de sempre',
        'meal_type': 'breakfast',
        'items': [
          {
            'food_id': 3,
            'name': 'Pão',
            'quantity': 50,
            'unit': 'g',
            'energy_kcal': 150,
          },
        ],
        'totals': {
          'energy_kcal': 150,
          'protein_g': 5,
          'carbs_g': 28,
          'fat_g': 2,
        },
        'usage_count': 3,
      });
      expect(t.items.single.quantity, 50);
      expect(t.items.single.foodId, 3);
    },
  );

  test('lista de compras: receita só na lista', () {
    final e = ShoppingExtraRecipe.fromJson({
      'recipe_id': 7,
      'title': 'Frango com arroz',
      'servings': 2,
    });
    expect(e.recipeId, 7);
    expect(e.servings, 2);
  });

  test('página de receitas expõe filtros e etiquetas', () {
    const RecipeFilters f = (
      search: null,
      mealType: null,
      tag: 'rápida',
      maxMinutes: 30,
      favorites: true,
    );
    expect(f.favorites, isTrue);
    final RecipeResults r = (recipes: [_recipe()], tags: ['rápida']);
    expect(r.tags, ['rápida']);
  });
}
