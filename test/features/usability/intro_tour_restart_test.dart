import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/app/app.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/auth/data/auth_repository.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/intro_tour/presentation/intro_tour_page.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets(
    'conclui sem rede, volta ao início e não reabre após reiniciar o app',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final base = testAccount();
      final account = Account(
        name: base.name,
        email: base.email,
        onboardingCompleted: true,
        consents: base.consents,
        profile: base.profile,
        introTourPending: true,
      );
      final repo = MockAuthRepository();
      when(() => repo.introTour('completed')).thenThrow(const NetworkFailure());
      Widget app() => ProviderScope(
        key: UniqueKey(),
        overrides: [
          ...sessionOverrides(SessionSignedIn(account)),
          authRepositoryProvider.overrideWithValue(repo),
          mealsOnDayProvider.overrideWith((ref, day) async => []),
          dashboardProvider.overrideWith(
            (ref, day) async => Dashboard.fromJson({
              'date': '2026-10-19',
              'is_today': true,
              'nutrition': {
                'meals_count': 0,
                'totals': <String, Object>{},
                'goals': <String, Object>{},
              },
              'water': {'total_ml': 0, 'goal_ml': 2000},
            }),
          ),
        ],
        child: const PicNutriApp(),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(IntroTourPage), findsOneWidget);
      for (var step = 0; step < 2; step++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      expect(find.byType(IntroTourPage), findsNothing);
      expect(find.text('Seu dia em equilíbrio'), findsOneWidget);
      // A API continua retornando pending=true: o recibo local deve impedir o loop.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(IntroTourPage), findsNothing);
      expect(find.text('Seu dia em equilíbrio'), findsOneWidget);
    },
  );
}
