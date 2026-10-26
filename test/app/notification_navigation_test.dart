import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/router.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/notifications/data/notification_repository.dart';
import 'package:picnutri/features/notifications/presentation/notifications_page.dart';

import '../features/notifications/notifications_page_test.dart'
    show FakeNotificationRepository;
import '../helpers/fakes.dart';

void main() {
  testWidgets('sino abre central e permite voltar e abrir novamente', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        ...sessionOverrides(SessionSignedIn(testAccount())),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(total: 0),
        ),
        dashboardProvider.overrideWith(
          (ref, day) => throw Exception('offline'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Notificações'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NotificationsPage), findsOneWidget);
      if (i == 0) {
        await tester.tap(find.byTooltip('Configurar notificações'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        router.pop();
        await tester.pumpAndSettle();
      }
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
