import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/food/presentation/meal_editor_page.dart';
import 'package:picnutri/features/food/presentation/repeat_meal_sheet.dart';
import 'package:picnutri/shared/state/selected_date.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fakes.dart';

Meal _meal({
  String id = 'm1',
  DateTime? at,
  List<Map<String, dynamic>>? items,
}) => Meal.fromJson({
  'id': id,
  'meal_type': 'lunch',
  'title': null,
  'eaten_at': (at ?? DateTime(2026, 10, 14, 12, 30)).toUtc().toIso8601String(),
  'local_date': '2026-10-14',
  'source': 'manual',
  'totals': {'energy_kcal': 450, 'protein_g': 35, 'carbs_g': 40, 'fat_g': 12},
  'items':
      items ??
      [
        {
          'food_id': 10,
          'name': 'Arroz',
          'quantity': 150,
          'unit': 'g',
          'energy_kcal': 190,
          'protein_g': 4,
          'carbs_g': 40,
          'fat_g': 0,
        },
        {
          'name': 'Frango grelhado',
          'quantity': 120,
          'unit': 'g',
          'energy_kcal': 260,
          'protein_g': 31,
          'carbs_g': 0,
          'fat_g': 12,
        },
      ],
});

/// Repositório falso: guarda as gravações; a primeira demora para simular rede lenta.
class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository() : super(Dio());

  final saved =
      <
        ({
          String? id,
          String type,
          DateTime eatenAt,
          List<MealItem> items,
          String? requestId,
        })
      >[];
  // Criado dentro do teste (zona do FakeAsync), senão o pump não o resolve.
  Completer<void> gate = Completer<void>();

  @override
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
    saved.add((
      id: id,
      type: mealType,
      eatenAt: eatenAt,
      items: items,
      requestId: requestId,
    ));
    await gate.future;
    return _meal(id: 'novo');
  }
}

void main() {
  late _FakeFoodRepository repo;

  setUp(() => repo = _FakeFoodRepository());

  Widget editor(Meal base, {DateTime? day}) => ProviderScope(
    overrides: [
      ...sessionOverrides(SessionSignedIn(testAccount())),
      foodRepositoryProvider.overrideWithValue(repo),
      if (day != null) selectedDateProvider.overrideWith(() => _FixedDay(day)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => context.push('/repeat'),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/repeat',
            builder: (_, _) => MealEditorPage(repeatFrom: base),
          ),
        ],
      ),
    ),
  );

  testWidgets(
    'abre a revisão preenchida, no dia selecionado, sem salvar nada',
    (tester) async {
      await tester.pumpWidget(editor(_meal(), day: DateTime(2026, 10, 10)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Repetir refeição'), findsOneWidget);
      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Frango grelhado'), findsOneWidget);
      expect(find.textContaining('Novo registro em'), findsOneWidget);
      expect(find.textContaining('10 de outubro'), findsOneWidget);
      expect(repo.saved, isEmpty);

      // Cancelar (voltar) não grava.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty);
    },
  );

  testWidgets(
    'registra um NOVO registro uma única vez, mesmo com toques repetidos',
    (tester) async {
      repo.gate = Completer<void>();
      await tester.pumpWidget(editor(_meal(), day: DateTime(2026, 10, 10)));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final register = find.text('Registrar refeição');
      await tester.scrollUntilVisible(
        register,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(register);
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
      await tester.pump();
      repo.gate.complete();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.text('abrir'),
        findsOneWidget,
        reason: 'volta ao diário após registrar',
      );
      expect(repo.saved, hasLength(1));
      final saved = repo.saved.single;
      expect(saved.id, isNull, reason: 'não altera a refeição original');
      expect(saved.requestId, isNotNull, reason: 'idempotente no servidor');
      expect(saved.type, 'lunch');
      expect(saved.items.map((i) => i.name), ['Arroz', 'Frango grelhado']);
      expect(saved.items.first.foodId, 10);
      expect(
        [saved.eatenAt.year, saved.eatenAt.month, saved.eatenAt.day],
        [2026, 10, 10],
      );
      expect([saved.eatenAt.hour, saved.eatenAt.minute], [12, 30]);
    },
  );

  testWidgets('revisão cabe em tela pequena com texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: editor(_meal(), day: DateTime(2026, 10, 10)),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Repetir refeição'), findsOneWidget);
  });

  test('rótulos de data das refeições recentes', () {
    expect(
      recentMealWhen(
        DateTime(2026, 10, 14, 12, 30),
        DateTime(2026, 10, 14, 20),
      ),
      'Hoje, 12:30',
    );
    expect(
      recentMealWhen(DateTime(2026, 10, 13, 8, 5), DateTime(2026, 10, 14, 20)),
      'Ontem, 08:05',
    );
  });

  test('recentes: últimos 14 dias, sem repetir a mesma composição', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': [
          _json('a', DateTime(2026, 10, 14, 12)),
          _json(
            'b',
            DateTime(2026, 10, 13, 12),
          ), // mesmos alimentos e quantidades de "a"
          _json('c', DateTime(2026, 10, 12, 8), item: 'Pão'),
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://api/'))
      ..httpClientAdapter = adapter;

    final meals = await FoodRepository(dio).recentMeals();

    expect(meals.map((m) => m.id), ['a', 'c']);
    expect(
      adapter.lastRequest!.queryParameters.keys,
      containsAll(['from', 'to']),
    );
  });
}

Map<String, dynamic> _json(String id, DateTime at, {String item = 'Arroz'}) => {
  'id': id,
  'meal_type': 'lunch',
  'eaten_at': at.toUtc().toIso8601String(),
  'local_date': '2026-10-14',
  'totals': {'energy_kcal': 100, 'protein_g': 2, 'carbs_g': 20, 'fat_g': 0},
  'items': [
    {
      'name': item,
      'quantity': 100,
      'unit': 'g',
      'energy_kcal': 100,
      'protein_g': 2,
      'carbs_g': 20,
      'fat_g': 0,
    },
  ],
};

class _FixedDay extends SelectedDate {
  _FixedDay(this.day);

  final DateTime day;

  @override
  DateTime build() => day;
}
