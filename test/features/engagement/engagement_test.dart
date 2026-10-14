import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/engagement/data/engagement_models.dart';
import 'package:picnutri/features/engagement/data/engagement_repository.dart';
import 'package:picnutri/features/engagement/presentation/engagement_widgets.dart';
import 'package:picnutri/features/reminders/data/reminder_models.dart';

import '../../helpers/fakes.dart';

class _FakeEngagementRepository implements EngagementRepository {
  int seenCalls = 0;

  @override
  Future<void> markAchievementsSeen() async => seenCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _achievement({bool achieved = true, bool isNew = false}) => {
  'code': 'streak_3',
  'title': '3 dias seguidos',
  'description': 'Fez registros em 3 dias consecutivos.',
  'icon': 'local_fire_department',
  'achieved': achieved,
  'achieved_at': achieved ? '2026-10-13T12:00:00+00:00' : null,
  'is_new': isNew,
};

void main() {
  test('interpreta o resumo de engajamento da API', () {
    final data = Engagement.fromJson({
      ...emptyEngagementJson(streak: 4, last7: 5, achievements: [_achievement(isNew: true)]),
      'challenges': {
        'active': [
          {
            'id': '01J',
            'code': 'water_5',
            'title': 'Semana hidratada',
            'description': '',
            'status': 'active',
            'progress': 2,
            'target': 5,
            'starts_on': '2026-10-10',
            'ends_on': '2026-10-16',
          },
        ],
        'recent': <Object>[],
        'available': [
          {'code': 'breakfast_5', 'title': 'Café', 'description': '', 'target': 5},
        ],
        'completed_count': 1,
      },
    });

    expect(data.currentStreak, 4);
    expect(data.last7Days, 5);
    expect(data.newlyUnlocked.single.code, 'streak_3');
    expect(data.activeChallenges.single.ratio, closeTo(0.4, 0.001));
    expect(data.availableChallenges.single.code, 'breakfast_5');
  });

  testWidgets('celebra conquista nova e marca como vista', (tester) async {
    final repo = _FakeEngagementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...sessionOverrides(
            SessionSignedIn(testAccount()),
            engagement: emptyEngagementJson(streak: 3, last7: 3, achievements: [_achievement(isNew: true)]),
          ),
          engagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: StreakCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 dias seguidos'), findsWidgets);
    expect(find.text('Nova conquista'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Nova conquista'), findsNothing);
    expect(repo.seenCalls, 1);
  });

  test('lembretes condicionais abrem a tela relacionada', () {
    Reminder r(String type) => Reminder(
      id: 'x',
      type: type,
      displayTitle: '',
      time: '20:00',
      days: const [1],
      enabled: true,
    );
    expect(r('water_goal').route, '/home/water');
    expect(r('daily_log').route, '/food');
    expect(r('weekly_summary').route, '/progress/reports');
    expect(r('custom').route, isNull);
    expect(ReminderLabels.hints.containsKey('water_goal'), isTrue);
  });
}
