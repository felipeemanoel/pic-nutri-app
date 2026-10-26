import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picnutri/app/app.dart';
import 'package:picnutri/app/routes.dart';
import 'package:picnutri/features/ai/data/ai_models.dart';
import 'package:picnutri/features/ai/data/ai_repository.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/social_sign_in.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/data/nutrition_models.dart';
import 'package:picnutri/features/help/data/help_repository.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/planning/data/planning_models.dart';
import 'package:picnutri/features/planning/data/planning_repository.dart';

import '../../helpers/fakes.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('login sem scroll com todos os provedores em $size', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...sessionOverrides(const SessionSignedOut()),
            socialProvidersProvider.overrideWith(
              (ref) async => {'google', 'facebook'},
            ),
          ],
          child: const PicNutriApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      for (final label in [
        'Entrar',
        'Continuar com Google',
        'Continuar com Facebook',
      ]) {
        final rect = tester.getRect(find.text(label));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Entrar')).bottom,
        lessThanOrEqualTo(size.height - 260),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem sessão, o app abre no login e valida os campos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: sessionOverrides(const SessionSignedOut()),
        child: const PicNutriApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta!'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('mostra o aviso de sessão expirada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: sessionOverrides(
          const SessionSignedOut(message: SessionController.expiredMessage),
        ),
        child: const PicNutriApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(SessionController.expiredMessage), findsOneWidget);
  });

  testWidgets('com sessão e onboarding pendente, abre a configuração inicial', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: sessionOverrides(
          SessionSignedIn(testAccount(onboarded: false)),
        ),
        child: const PicNutriApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vamos montar o seu plano'), findsOneWidget);
  });

  testWidgets(
    'com sessão completa, abre as 5 abas e acessa o assistente pelo Perfil',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...sessionOverrides(SessionSignedIn(testAccount())),
            mealsOnDayProvider.overrideWith((ref, day) async => []),
            nutritionSummaryProvider.overrideWith(
              (ref, day) async => NutritionSummary.fromJson(
                _emptyDashboard['nutrition']! as Map<String, dynamic>,
              ),
            ),
            recipeSearchProvider.overrideWith(
              (ref, filters) async => (recipes: <Recipe>[], tags: <String>[]),
            ),
            helpArticlesProvider.overrideWith((ref, filters) async => []),
            conversationsProvider.overrideWith((ref) async => []),
            aiStatusProvider.overrideWith(
              (ref) async => AiStatus.fromJson({
                'photo_analysis': {'available': false},
                'assistant': {'available': true, 'limit': 3, 'remaining': 3},
              }),
            ),
            // Sem API nos testes: o painel recebe um dia vazio.
            dashboardProvider.overrideWith(
              (ref, day) async => Dashboard.fromJson(_emptyDashboard),
            ),
          ],
          child: const PicNutriApp(),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in ['Início', 'Alimentação', 'Evolução', 'Conteúdo']) {
        expect(find.text(label), findsWidgets);
      }
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Assistente'),
        ),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Conteúdo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Receitas'), findsOneWidget);
      expect(find.text('Informações de saúde'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      // O endereço antigo também seleciona a aba Conteúdo.
      final router = GoRouter.of(tester.element(find.byType(NavigationBar)));
      router.go(AppRoutes.legacyContents);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.contents,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );

      // Profissionais saiu da barra inferior: abre pelo Perfil.
      expect(find.text('Profissionais'), findsNothing);

      // Perfil fica na quinta aba; o topo oferece somente notificações.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Perfil'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.byTooltip('Perfil e configurações'), findsNothing);
      expect(find.text('Adicionar foto'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Assistente'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Assistente')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assistente'));
      await tester.pumpAndSettle();
      expect(find.text('Assistente PicNutri'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Conteúdo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      // Links antigos não abrem a descrição nem solicitam o microfone.
      await tester.binding.setSurfaceSize(const Size(800, 844));
      router.go(AppRoutes.mealText);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.food);
      expect(find.text('Refeição por texto ou voz'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

const _emptyDashboard = <String, dynamic>{
  'date': '2026-10-13',
  'is_today': true,
  'nutrition': {
    'meals_count': 0,
    'totals': {'energy_kcal': 0, 'protein_g': 0, 'carbs_g': 0, 'fat_g': 0},
    'goals': <String, dynamic>{},
    'energy_remaining_kcal': null,
  },
  'water': {'total_ml': 0, 'goal_ml': 2000},
  'weight': null,
  'goal': null,
  'medication_tracking_enabled': false,
};
