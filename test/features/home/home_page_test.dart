import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/home/presentation/home_page.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _dashboardJson({
  int meals = 0,
  double kcal = 0,
  Map<String, dynamic>? weight,
}) => {
  'date': '2026-10-13',
  'is_today': true,
  'nutrition': {
    'meals_count': meals,
    'totals': {'energy_kcal': kcal, 'protein_g': 0, 'carbs_g': 0, 'fat_g': 0},
    'goals': {
      'energy_kcal': 1800,
      'protein_g': null,
      'carbs_g': null,
      'fat_g': null,
    },
    'energy_remaining_kcal': 1800 - kcal,
  },
  'water': {'total_ml': 500, 'goal_ml': 2000},
  'weight': weight,
  'goal': null,
  'medication_tracking_enabled': false,
};

Widget _app(Dashboard data, {List<Meal> meals = const []}) => ProviderScope(
  overrides: [
    ...sessionOverrides(SessionSignedIn(testAccount())),
    dashboardProvider.overrideWith((ref, day) async => data),
    mealsOnDayProvider.overrideWith((ref, day) async => meals),
  ],
  child: const MaterialApp(home: HomePage()),
);

Meal _meal(String type, double kcal) => Meal.fromJson({
  'id': type,
  'meal_type': type,
  'eaten_at': '2026-10-13T12:00:00Z',
  'local_date': '2026-10-13',
  'source': 'manual',
  'totals': {'energy_kcal': kcal, 'protein_g': 0, 'carbs_g': 0, 'fat_g': 0},
});

void main() {
  testWidgets('sem registros, orienta a começar em vez de mostrar números', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Dashboard.fromJson(_dashboardJson())));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma refeição registrada neste dia.'), findsOneWidget);
    expect(find.text('Suas refeições do dia aparecem aqui.'), findsOneWidget);
    expect(find.text('Registrar refeição'), findsOneWidget, reason: 'uma ação principal, sem repetição');
    expect(find.text('500 de 2.000 ml'), findsOneWidget);

  });

  testWidgets('home em celular: só o essencial de hoje, sem estourar', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Dashboard.fromJson(_dashboardJson())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Sequência, semana e conteúdos foram para a Evolução e a Alimentação.
    expect(find.text('Sua sequência'), findsNothing);
    expect(find.text('Hábitos e conquistas'), findsNothing);
    // O Início é sempre hoje: sem navegador de dias.
    expect(find.byTooltip('Dia anterior'), findsNothing);
    // Próximo passo: o que falta, sem repetir os números dos cartões acima.
    await tester.scrollUntilVisible(find.text('Faltam 1.500 ml de água'), 200);
    expect(find.text('Registrar água'), findsOneWidget);
    expect(find.text('Registrar refeição'), findsOneWidget);
  });

  testWidgets('água: menu com outros volumes além de +200 ml', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Dashboard.fromJson(_dashboardJson())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Outras quantidades de água'));
    await tester.pumpAndSettle();
    expect(find.text('+300 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);
    expect(find.text('Outra quantidade'), findsOneWidget);
  });

  testWidgets('com refeições, mostra o equilíbrio do dia e a lista', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Dashboard.fromJson(_dashboardJson(meals: 2, kcal: 1250)),
        meals: [_meal('lunch', 580), _meal('breakfast', 320)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.250'), findsOneWidget);
    expect(find.text('de 1.800 kcal'), findsOneWidget);
    expect(find.text('550 kcal'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Registrado · 320 kcal'), findsOneWidget);
  });
}
