import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/progress/data/body_repository.dart';
import 'package:picnutri/features/progress/presentation/progress_page.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets(
    'medicamento fica visível antes de ativar e explica como começar',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...sessionOverrides(SessionSignedIn(testAccount())),
            bodyProgressProvider.overrideWith(
              (ref, days) async => throw Exception('Sem dados de teste'),
            ),
            weightEntriesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: ProgressPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Medicamento'), findsOneWidget);
      await tester.tap(find.text('Medicamento'));
      await tester.pumpAndSettle();
      expect(find.text('Acompanhe seu medicamento'), findsOneWidget);
      expect(find.text('Ativar no perfil'), findsOneWidget);
      expect(find.text('Aplicação'), findsNothing);
    },
  );
}
