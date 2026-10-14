import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/system_status/data/system_health.dart';
import 'package:picnutri/features/system_status/presentation/system_status_page.dart';
import 'package:picnutri/features/system_status/presentation/system_status_providers.dart';

const _env = AppEnv(flavor: AppFlavor.dev, apiBaseUrl: 'http://localhost:8080');

Widget _wrap(Future<SystemHealth> Function() fetch) {
  return ProviderScope(
    retry: noAutomaticRetry,
    overrides: [
      appEnvProvider.overrideWithValue(_env),
      systemHealthProvider.overrideWith((ref) => fetch()),
    ],
    child: const MaterialApp(home: SystemStatusPage()),
  );
}

void main() {
  testWidgets('mostra ambiente e serviços saudáveis', (tester) async {
    await tester.pumpWidget(
      _wrap(
        () async => const SystemHealth(
          status: 'ok',
          environment: 'local',
          checks: {'database': true, 'cache': true, 'storage': true},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('dev'), findsOneWidget);
    expect(find.text('http://localhost:8080/api/v1'), findsOneWidget);
    expect(find.text('API operando normalmente'), findsOneWidget);
    expect(find.text('Banco de dados'), findsOneWidget);
  });

  testWidgets('mostra mensagem amigável e permite tentar de novo', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(() async {
        calls++;
        throw const NetworkFailure();
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text(const NetworkFailure().message), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(calls, 2);
  });
}
