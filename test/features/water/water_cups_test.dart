import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/features/water/presentation/water_cups.dart';
void main() {
  testWidgets('copo parcial registra somente o volume restante', (tester) async {
    int? amount;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: WaterCups(totalMl: 150, goalMl: 450, onAdd: (ml) => amount = ml))));
    await tester.tap(find.byTooltip('Registrar 50 ml').first);
    expect(amount, 50);
    expect(find.byTooltip('Registrar 200 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('meta concluída não permite registrar novamente os copos cheios', (tester) async {
    int calls = 0;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: WaterCups(totalMl: 600, goalMl: 450, onAdd: (_) => calls++))));
    await tester.tap(find.byTooltip('200 ml registrados').first);
    expect(calls, 0);
    expect(find.text('Meta do dia alcançada'), findsOneWidget);
  });
}
