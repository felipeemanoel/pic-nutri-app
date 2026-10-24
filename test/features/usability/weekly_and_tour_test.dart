import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/auth/data/auth_repository.dart';
import 'package:picnutri/features/intro_tour/presentation/intro_tour_page.dart';
import 'package:picnutri/features/reports/data/report_models.dart';
import 'package:picnutri/features/reports/data/report_repository.dart';
import 'package:picnutri/features/reports/presentation/weekly_summary_card.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _summary({int days = 0, int water = 0, int protein = 0}) =>
    {
      'days_logged': days,
      'avg_energy_kcal': null,
      'avg_protein_g': null,
      'avg_carbs_g': null,
      'avg_fat_g': null,
      'avg_water_ml': null,
      'days_calories_met': 0,
      'days_protein_met': protein,
      'days_water_met': water,
    };

PeriodReport _report({
  bool inProgress = true,
  int elapsed = 4,
  int logged = 0,
  int water = 0,
  int protein = 0,
  int previous = 0,
  int? proteinGoal,
  Map<String, dynamic>? weight,
}) => PeriodReport.fromJson({
  'period': 'week',
  'from': '2026-10-13',
  'to': '2026-10-19',
  'days_elapsed': elapsed,
  'in_progress': inProgress,
  'goals': {'energy_kcal': 1800, 'protein_g': proteinGoal, 'water_ml': 2000},
  'summary': _summary(days: logged, water: water, protein: protein),
  'previous': {
    ..._summary(days: previous),
    'from': '2026-10-06',
    'to': '2026-10-12',
  },
  'weight': weight,
  'meals_by_type': <Object>[],
  'days': <Object>[],
});

void main() {
  group('resumo semanal', () {
    test('semana em andamento conta só os dias até hoje', () {
      final t = WeeklySummaryText(_report(logged: 3, water: 2));
      expect(t.status, 'Em andamento');
      expect(t.title, 'Sua semana');
      expect(t.daysLogged, '3 de 4 dias até agora com registros');
      expect(t.goals, [
        'Meta de água: 2 de 4 dias',
      ]); // proteína sem meta: não aparece
      expect(t.gapsNote, contains('nada foi anotado'));
    });

    test('semana concluída e comparação só com dados suficientes', () {
      final concluded = WeeklySummaryText(
        _report(
          inProgress: false,
          elapsed: 7,
          logged: 5,
          previous: 4,
          proteinGoal: 90,
          protein: 3,
        ),
      );
      expect(concluded.status, 'Concluída');
      expect(concluded.daysLogged, '5 de 7 dias com registros');
      expect(concluded.goals, contains('Meta de proteína: 3 de 7 dias'));
      expect(concluded.comparison, 'Semana anterior: 4 dias com registros');

      expect(
        WeeklySummaryText(_report(logged: 5, previous: 2)).comparison,
        isNull,
      );
      expect(
        WeeklySummaryText(_report(logged: 2, previous: 6)).comparison,
        isNull,
      );
    });

    test('peso aparece só com dois registros, sem julgamento', () {
      expect(WeeklySummaryText(_report(logged: 2)).weight, isNull);
      expect(
        WeeklySummaryText(
          _report(
            logged: 2,
            weight: {
              'first_kg': 80,
              'last_kg': 79.6,
              'change_kg': -0.4,
              'entries': 2,
            },
          ),
        ).weight,
        'Peso: variação de -0,4 kg na semana',
      );
    });

    Widget card(Future<PeriodReport> Function() load) => ProviderScope(
      // Como no app: sem nova tentativa automática (o usuário decide).
      retry: noAutomaticRetry,
      overrides: [
        appEnvProvider.overrideWithValue(testEnv),
        periodReportProvider.overrideWith((ref, q) => load()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: WeeklySummaryCard())),
      ),
    );

    testWidgets('conta nova recebe orientação, não números', (tester) async {
      await tester.pumpWidget(card(() async => _report()));
      await tester.pumpAndSettle();

      expect(find.text('Em andamento'), findsOneWidget);
      expect(
        find.textContaining('Seu resumo aparece aqui conforme você registra'),
        findsOneWidget,
      );
      expect(find.textContaining('dias com registros'), findsNothing);
    });

    testWidgets('erro mostra mensagem e permite tentar de novo', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        card(() async {
          calls++;
          if (calls == 1) throw const NetworkFailure();
          return _report(logged: 1, elapsed: 1);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 1 dia até agora com registros'), findsOneWidget);
    });

    testWidgets('cabe em tela pequena com texto ampliado', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: card(
            () async => _report(
              inProgress: false,
              elapsed: 7,
              logged: 5,
              water: 3,
              previous: 4,
              proteinGoal: 90,
              protein: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Concluída'), findsOneWidget);
    });
  });

  group('primeira visita guiada', () {
    late MockAuthRepository repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      repo = MockAuthRepository();
      when(() => repo.introTour(any())).thenAnswer((_) async => testAccount());
    });

    Widget tour({bool review = false}) => ProviderScope(
      overrides: [
        ...sessionOverrides(SessionSignedIn(testAccount())),
        authRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/tour'),
                    child: const Text('início'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/tour',
              builder: (_, _) => IntroTourPage(review: review),
            ),
          ],
        ),
      ),
    );

    Future<void> open(WidgetTester tester, {bool review = false}) async {
      await tester.pumpWidget(tour(review: review));
      await tester.tap(find.text('início'));
      await tester.pumpAndSettle();
    }

    testWidgets('três etapas com Próximo e Concluir; conclusão é salva', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Registre suas refeições'), findsOneWidget);

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Registre a água'), findsOneWidget);

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Acompanhe metas e evolução'), findsOneWidget);
      expect(find.text('Concluir'), findsOneWidget);

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      verify(() => repo.introTour('completed')).called(1);
      expect(find.text('início'), findsOneWidget);
    });

    testWidgets('Pular dispensa e não mostra de novo', (tester) async {
      await open(tester);
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      verify(() => repo.introTour('skipped')).called(1);
      expect(find.text('início'), findsOneWidget);
    });

    testWidgets('revisão pela ajuda não altera o estado salvo', (tester) async {
      await open(tester, review: true);
      expect(find.text('Fechar'), findsOneWidget);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.introTour(any()));
    });

    testWidgets('sem rede, fecha mesmo assim', (tester) async {
      when(() => repo.introTour(any())).thenThrow(const NetworkFailure());
      await open(tester);
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('início'), findsOneWidget);
    });

    testWidgets('cabe em tela pequena com texto ampliado e anuncia a etapa', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: tour(),
        ),
      );
      await tester.tap(find.text('início'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel(RegExp('Etapa 1 de 3')), findsOneWidget);
      semantics.dispose();
    });

    test('a conta informa se o guia está pendente', () {
      final pending = Account.fromJson({
        'name': 'Ana',
        'email': 'a@b.com',
        'onboarding_completed': true,
        'onboarding': {'completed': true, 'intro_tour_pending': true},
        'consents': <String, dynamic>{},
        'profile': <String, dynamic>{},
      });
      expect(pending.introTourPending, isTrue);
      expect(testAccount().introTourPending, isFalse);
    });
  });
}
