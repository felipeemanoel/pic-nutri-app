import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/shared/widgets/keyboard_dismiss.dart';

void main() {
  testWidgets('teclado numérico pode fechar e botão fixo fica acima dele', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardDismiss(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: ListView(
              children: [
                TextField(focusNode: focus, keyboardType: TextInputType.number),
                const SizedBox(height: 1000),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: FilledButton(
                onPressed: () {},
                child: const Text('Continuar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.getRect(find.text('Continuar')).bottom, lessThan(500));
    expect(find.text('Fechar teclado'), findsOneWidget);
    await tester.tap(find.text('Fechar teclado'));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
