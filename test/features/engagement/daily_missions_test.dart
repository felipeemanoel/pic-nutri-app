import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/features/engagement/data/daily_missions.dart';
import 'package:picnutri/features/engagement/presentation/daily_missions_card.dart';

DailyMissions progress(int days, {bool broken = false}) => DailyMissions(
  streak: days,
  bestStreak: 100,
  streakBroken: broken,
  missions: const [
    DailyMission(code: 'visit', title: 'Entrar no aplicativo', completed: true),
    DailyMission(
      code: 'record',
      title: 'Registrar ou atualizar um cuidado',
      completed: false,
    ),
  ],
);

void main() {
  test(
    'níveis respeitam todos os limites e reiniciam após perda da sequência',
    () {
      for (final (days, level) in [
        (0, MissionLevel.beginner),
        (2, MissionLevel.beginner),
        (3, MissionLevel.bronze),
        (9, MissionLevel.bronze),
        (10, MissionLevel.silver),
        (29, MissionLevel.silver),
        (30, MissionLevel.gold),
        (99, MissionLevel.gold),
        (100, MissionLevel.diamond),
        (101, MissionLevel.diamond),
      ]) {
        expect(progress(days).level, level);
      }
      expect(progress(100).nextLevel, isNull);
      expect(progress(0, broken: true).level, MissionLevel.beginner);
      expect(progress(10).stars, 1);
    },
  );

  testWidgets('celebra nível em tela estreita com texto ampliado', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMissionsProvider.overrideWith((ref) async => progress(10)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: const SingleChildScrollView(child: DailyMissionsCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Parabéns! Você conquistou o nível Prata!'),
      findsOneWidget,
    );
    expect(find.text('1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
