import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
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

Widget _app(Dashboard data) => ProviderScope(
  overrides: [
    ...sessionOverrides(SessionSignedIn(testAccount())),
    dashboardProvider.overrideWith((ref, day) async => data),
  ],
  child: const MaterialApp(home: HomePage()),
);

void main() {
  testWidgets('sem registros, orienta a começar em vez de mostrar números', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Dashboard.fromJson(_dashboardJson())));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma refeição registrada neste dia.'), findsOneWidget);
    expect(
      find.text(
        'Registre seu peso na aba Evolução para acompanhar seu progresso.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('500 ml'), findsWidgets);
  });

  testWidgets('com refeições e peso, mostra os indicadores reais', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Dashboard.fromJson(
          _dashboardJson(
            meals: 2,
            kcal: 1250,
            weight: {
              'latest_kg': 79.5,
              'latest_date': '2026-10-12',
              'change_30d_kg': -1.2,
              'series_30d': [
                {'date': '2026-09-20', 'weight_kg': 80.7},
                {'date': '2026-10-12', 'weight_kg': 79.5},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.250 kcal'), findsOneWidget);
    expect(find.text('550 kcal'), findsOneWidget);
    expect(find.text('79,5 kg'), findsOneWidget);
    expect(find.text('−1,2 kg'), findsOneWidget);
  });
}
