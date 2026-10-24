import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/progress/data/body_repository.dart';
import 'package:picnutri/features/progress/presentation/progress_page.dart';

import '../../helpers/fakes.dart';

Widget _app({required bool medication}) => ProviderScope(
  overrides: [
    ...sessionOverrides(
      SessionSignedIn(testAccount(medicationTracking: medication)),
    ),
    bodyProgressProvider.overrideWith(
      (ref, days) async => throw Exception('Sem dados de teste'),
    ),
    weightEntriesProvider.overrideWith((ref) async => []),
  ],
  child: const MaterialApp(home: ProgressPage()),
);

void main() {
  testWidgets('sem acompanhamento ativo, a aba de medicamento não aparece', (
    tester,
  ) async {
    await tester.pumpWidget(_app(medication: false));
    await tester.pumpAndSettle();
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Medicamento'), findsNothing);
  });

  testWidgets('com acompanhamento ativo, a aba de medicamento aparece', (
    tester,
  ) async {
    await tester.pumpWidget(_app(medication: true));
    await tester.pumpAndSettle();
    expect(find.text('Medicamento'), findsOneWidget);
  });

  testWidgets('o resumo da Evolução leva a relatórios, hábitos e bem-estar', (
    tester,
  ) async {
    await tester.pumpWidget(_app(medication: false));
    await tester.pumpAndSettle();
    expect(find.text('Relatórios'), findsOneWidget);
    expect(find.text('Hábitos e conquistas'), findsOneWidget);
    expect(find.text('Bem-estar'), findsOneWidget);
  });
}
