import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/app.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';

import 'helpers/fakes.dart';

/// Teste de fumaça: o app inteiro (tema, rotas, localização) monta sem erros.
void main() {
  testWidgets('PicNutriApp monta e abre o login sem sessão', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: sessionOverrides(const SessionSignedOut()),
        child: const PicNutriApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar no PicNutri'), findsOneWidget);
  });
}
