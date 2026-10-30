import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/features.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/ai/data/ai_repository.dart';
import 'package:picnutri/features/food/data/food_repository.dart';
import 'package:picnutri/features/food/presentation/food_page.dart';

void main() {
  testWidgets('registro oferece as opções ativas sem mostrar texto ou voz', (
    tester,
  ) async {
    expect(AppFeatures.mealTextVoice, isFalse);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recentMealsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => chooseHowToAddMeal(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Falar ou escrever'), findsNothing);
    expect(find.text('Ditar por voz'), findsNothing);
    expect(find.text('Como você quer registrar?'), findsOneWidget);
    expect(find.text('Tirar foto do prato'), findsOneWidget);
    expect(find.text('Usar foto da galeria'), findsOneWidget);
    // Sem o Início, a folha mostra só as formas de registrar refeição.
    expect(find.text('Também registrar'), findsNothing);
    expect(find.text('Buscar alimentos'), findsOneWidget);
    expect(find.text('Recentes'), findsOneWidget);
    expect(find.text('Favoritas'), findsOneWidget);
  });
  test(
    'repositório recusa envio por texto enquanto o recurso estiver OFF',
    () async {
      var requests = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests++;
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );
      await expectLater(
        AiRepository(dio).describeMeal('Minha refeição', requestId: 'test'),
        throwsA(isA<BusinessFailure>()),
      );
      expect(requests, 0);
    },
  );
}
