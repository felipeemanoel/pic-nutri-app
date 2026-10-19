import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnutri/main.dart' as app;

/// Roda o app real contra a API do ambiente escolhido (backend no ar):
/// flutter test integration_test --dart-define-from-file=env/dev.json
///
/// Requer um aparelho/emulador sem sessão salva do PicNutri.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre o app e chega à tela de login', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
