import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/app.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';

import '../../helpers/fakes.dart';

void main() {
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

    expect(find.text('Bem-vindo de volta'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Senha obrigatório'), findsOneWidget);
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

    expect(find.text('Bem-vindo(a)'), findsOneWidget);
  });

  testWidgets('com sessão completa, abre o início com as 5 abas', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...sessionOverrides(SessionSignedIn(testAccount())),
          mealsOnDayProvider.overrideWith((ref, day) async => []),
          // Sem API nos testes: o painel recebe um dia vazio.
          dashboardProvider.overrideWith(
            (ref, day) async => Dashboard.fromJson(_emptyDashboard),
          ),
        ],
        child: const PicNutriApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Início',
      'Alimentação',
      'Evolução',
      'Assistente',
      'Profissionais',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    // Perfil fica fora das abas, no avatar do topo.
    await tester.tap(find.byTooltip('Perfil e configurações').first);
    await tester.pumpAndSettle();
    expect(find.text('Maria Silva'), findsOneWidget);
  });
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
