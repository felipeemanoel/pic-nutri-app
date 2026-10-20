import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/engagement/data/engagement_models.dart';
import 'package:picnutri/features/engagement/data/engagement_repository.dart';
import 'package:picnutri/features/engagement/presentation/celebrations.dart';

import '../../helpers/fakes.dart';

/// Servidor falso: devolve as pendentes até serem marcadas como vistas.
class _FakeEngagementRepository implements EngagementRepository {
  _FakeEngagementRepository(this.pending);

  List<Celebration> pending;
  final seen = <List<String>>[];
  bool failSeen = false;

  @override
  Future<List<Celebration>> celebrations() async => pending;

  @override
  Future<void> markCelebrationsSeen(List<String> keys) async {
    seen.add(keys);
    if (failSeen) throw Exception('sem rede');
    pending = pending.where((c) => !keys.contains(c.key)).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _firstMeal = Celebration(
  key: 'achievement:first_meal',
  kind: 'achievement',
  title: 'Primeiro registro',
  message: 'Registrou a primeira refeição.',
  icon: 'restaurant',
);
const _water = Celebration(
  key: 'water_goal:2026-10-19',
  kind: 'water_goal',
  title: 'Meta de água do dia',
  message: 'Você alcançou sua meta de água hoje.',
  icon: 'water_drop',
);

/// O aviso some sozinho em ~6 s (o temporizador começa após a animação de entrada).
Future<void> waitDismiss(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

void main() {
  Widget app(_FakeEngagementRepository repo, {bool reduceMotion = false}) =>
      ProviderScope(
        overrides: [
          ...sessionOverrides(SessionSignedIn(testAccount())),
          engagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const Scaffold(body: CelebrationHost(child: Text('início'))),
        ),
      );

  testWidgets(
    'agrupa celebrações simultâneas num aviso que não bloqueia o app',
    (tester) async {
      final repo = _FakeEngagementRepository([_firstMeal, _water]);
      await tester.pumpWidget(app(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Boas notícias!'), findsOneWidget);
      expect(find.text('• Primeiro registro'), findsOneWidget);
      expect(find.text('• Meta de água do dia'), findsOneWidget);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'não é um diálogo modal',
      );
      expect(find.text('início'), findsOneWidget);
      expect(repo.seen, [
        ['achievement:first_meal', 'water_goal:2026-10-19'],
      ]);
    },
  );

  testWidgets(
    'cada celebração aparece uma vez: não repete ao atualizar nem ao reabrir',
    (tester) async {
      final repo = _FakeEngagementRepository([_firstMeal]);
      await tester.pumpWidget(app(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Primeiro registro'), findsOneWidget);

      // O aviso some e o app atualiza (ex.: novo registro): o servidor já não devolve a celebração.
      // Some sozinho depois de alguns segundos (o app segue utilizável o tempo todo).
      await waitDismiss(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('início')),
      );
      container.invalidate(celebrationsProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsNothing);

      // "Reabrir o app": novo ProviderScope com o mesmo servidor.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsNothing);
      expect(repo.seen, hasLength(1));
    },
  );

  testWidgets('sem rede ao confirmar, não repete na mesma sessão', (
    tester,
  ) async {
    final repo = _FakeEngagementRepository([_water])..failSeen = true;
    await tester.pumpWidget(app(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Some sozinho depois de alguns segundos (o app segue utilizável o tempo todo).
    await waitDismiss(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.text('início')),
    );
    container.invalidate(celebrationsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('com movimento reduzido, o ícone não anima', (tester) async {
    final repo = _FakeEngagementRepository([_water]);
    await tester.pumpWidget(app(repo, reduceMotion: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Meta de água do dia'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CelebrationContent),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsNothing,
    );
  });

  test('lê a celebração da API', () {
    final c = Celebration.fromJson({
      'key': 'protein_goal:2026-10-19',
      'kind': 'protein_goal',
      'title': 'Meta de proteína do dia',
      'message': 'Você alcançou sua meta de proteínas hoje.',
      'icon': 'egg',
    });
    expect(c.kind, 'protein_goal');
    expect(c.key, endsWith('2026-10-19'));
  });
}
