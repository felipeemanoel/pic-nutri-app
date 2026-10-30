import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/activity/data/activity_models.dart';
import 'package:picnutri/features/activity/domain/activity_math.dart';

ActivityPlan _plan({List<int> days = const [], String? time = '07:00'}) =>
    ActivityPlan(
      id: 'p',
      type: 'strength',
      typeLabel: 'Musculação',
      timesPerWeek: 3,
      days: days,
      time: time,
      reminderEnabled: true,
      isActive: true,
    );

void main() {
  const strength = ActivityTypeOption(
    value: 'strength',
    label: 'Musculação',
    met: 5,
    supportsDistance: false,
  );
  const vigorous = IntensityOption(
    value: 'vigorous',
    label: 'Intensa',
    factor: 1.25,
  );

  test('gasto estimado = MET × intensidade × peso × horas', () {
    expect(
      ActivityMath.estimatedKcal(type: strength, durationMin: 60, weightKg: 80),
      400,
    );
    expect(
      ActivityMath.estimatedKcal(
        type: strength,
        durationMin: 60,
        weightKg: 80,
        intensity: vigorous,
      ),
      500,
    );
    expect(
      ActivityMath.estimatedKcal(type: strength, durationMin: 60),
      isNull,
      reason: 'sem peso não há estimativa',
    );
  });

  test('ritmo e duração', () {
    expect(ActivityMath.pace(30, 5), '6:00 /km');
    expect(ActivityMath.pace(58, 10), '5:48 /km');
    expect(ActivityMath.pace(30, null), isNull);
    expect(ActivityMath.duration(45), '45min');
    expect(ActivityMath.duration(60), '1h');
    expect(ActivityMath.duration(75), '1h 15min');
  });

  test('texto do agendamento', () {
    expect(
      ActivityMath.schedule(_plan(days: [1, 3, 5])),
      '3x por semana · seg, qua, sex · 07:00',
    );
    expect(ActivityMath.schedule(_plan(time: null)), '3x por semana');
  });

  test('próximo horário respeita dias e hora', () {
    // Quarta, 28/10/2026, 08:00 → próxima sexta às 7h.
    final now = DateTime(2026, 10, 28, 8);
    expect(
      ActivityMath.nextSlot(_plan(days: [1, 3, 5]), now),
      DateTime(2026, 10, 30, 7),
    );
    // Sem dias: amanhã às 7h (hoje já passou).
    expect(ActivityMath.nextSlot(_plan(), now), DateTime(2026, 10, 29, 7));
    expect(ActivityMath.nextSlot(_plan(time: null), now), isNull);
  });

  test('resumo lê a semana e o progresso das metas', () {
    final s = ActivitySummary.fromJson({
      'week': {
        'start': '2026-10-26',
        'end': '2026-11-01',
        'sessions': 2,
        'minutes': 90,
        'active_days': 2,
        'distance_km': 5,
      },
      'weekly_goal': 4,
      'streak_weeks': 1,
      'plans': [
        {
          'id': 'p',
          'type': 'running',
          'type_label': 'Corrida',
          'times_per_week': 2,
          'days': <int>[],
          'is_active': true,
          'done_this_week': 2,
          'done_days': [2, 4],
        },
      ],
      'upcoming_events': <Object>[],
      'recent_sessions': <Object>[],
    });
    expect(s.weekProgress, 0.5);
    expect(s.plans.single.goalMet, isTrue);
    expect(s.plans.single.displayName, 'Corrida');
  });
}
