import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/activity/data/activity_models.dart';
import 'package:picnutri/features/activity/data/activity_repository.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/home/presentation/home_page.dart';
import 'package:picnutri/features/medication/application/medication_overview.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';
import 'package:picnutri/features/medication/domain/medication_schedule.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _dashboardJson({
  int meals = 0,
  double kcal = 0,
  Map<String, dynamic>? weight,
  bool medication = false,
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
  'medication_tracking_enabled': medication,
};

const _activityJson = <String, dynamic>{
  'week': {
    'start': '2026-10-26',
    'end': '2026-11-01',
    'sessions': 1,
    'minutes': 60,
    'active_days': 1,
    'distance_km': 0,
  },
  'weekly_goal': 3,
  'streak_weeks': 0,
  'plans': [
    {
      'id': 'p1',
      'type': 'strength',
      'type_label': 'Musculação',
      'title': 'Academia',
      'times_per_week': 3,
      'days': [1, 3, 5],
      'time': '07:00',
      'reminder_enabled': true,
      'is_active': true,
      'done_this_week': 1,
      'done_days': [1],
    },
  ],
  'upcoming_events': <Object>[],
  'recent_sessions': <Object>[],
};

Widget _app(
  Dashboard data, {
  List<Meal> meals = const [],
  MedicationOverview? medication,
}) => ProviderScope(
  overrides: [
    ...sessionOverrides(SessionSignedIn(testAccount())),
    dashboardProvider.overrideWith((ref, day) async => data),
    mealsOnDayProvider.overrideWith((ref, day) async => meals),
    medicationOverviewProvider.overrideWith((ref) async => medication),
    activitySummaryProvider.overrideWith(
      (ref) async => ActivitySummary.fromJson(_activityJson),
    ),
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
    expect(
      find.text('Registrar'),
      findsOneWidget,
      reason: 'uma ação principal, sem repetição',
    );
    expect(find.text('0,5 / 2 L'), findsOneWidget);
    expect(
      find.byTooltip('Desfazer o último registro de água'),
      findsOneWidget,
    );
    // Sem acompanhamento de medicação, o cartão da próxima aplicação não aparece.
    expect(find.text('Próxima aplicação'), findsNothing);
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
    expect(find.text('Registrar'), findsOneWidget);
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

    expect(find.text('1.250 / 1.800 kcal'), findsOneWidget);
    expect(find.text('550 kcal para sua meta'), findsOneWidget);
    expect(find.text('Almoço'), findsOneWidget);
    expect(find.text('Registrado · 320 kcal'), findsOneWidget);
  });

  testWidgets('com medicação, a próxima aplicação abre o Início', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final last = DateTime.now().subtract(const Duration(days: 2, minutes: 55));
    final medication = Medication(
      id: 'm1',
      name: 'Mounjaro',
      form: 'injection',
      doseUnit: 'mg',
      frequency: 'weekly',
      isActive: true,
      lastDoseAt: last,
    );
    final dose = MedicationDose(
      id: 'd1',
      medicationId: 'm1',
      takenAt: last,
      localDate: '',
      doseUnit: 'mg',
      doseAmount: 2.5,
      symptoms: const [],
    );
    await tester.pumpWidget(
      _app(
        Dashboard.fromJson(_dashboardJson(medication: true)),
        medication: MedicationOverview(
          medication: medication,
          doses: [dose],
          lastDose: dose,
          level: MedicationLevel(
            ingredient: ActiveIngredient.tirzepatide,
            doses: [dose],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Próxima aplicação'), findsOneWidget);
    expect(find.text('4d 23h'), findsOneWidget);
    expect(find.text('Mounjaro · 2,5 mg'), findsOneWidget);
    expect(find.text('Registrar aplicação'), findsOneWidget);
    expect(find.textContaining('mg'), findsWidgets);
  });

  testWidgets('atividade física: treinos da semana e metas no Início', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Dashboard.fromJson(_dashboardJson())));
    await tester.pumpAndSettle();
    expect(find.text('Atividade física'), findsOneWidget);
    expect(find.text('1 / 3 treinos na semana'), findsOneWidget);
    expect(find.text('Academia 1/3'), findsOneWidget);
    expect(find.text('Registrar treino'), findsOneWidget);
  });
}
