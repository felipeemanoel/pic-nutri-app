import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/activity/application/activity_reminders.dart';
import 'package:picnutri/features/activity/data/activity_models.dart';

ActivityPlan _plan({
  List<int> days = const [1, 3, 5],
  String? time = '07:00',
  bool reminder = true,
  bool active = true,
}) => ActivityPlan(
  id: 'p1',
  type: 'strength',
  typeLabel: 'Musculação',
  title: 'Academia',
  location: 'Boa Viagem',
  timesPerWeek: 3,
  days: days,
  time: time,
  reminderEnabled: reminder,
  isActive: active,
);

ActivityEvent _event(DateTime at, {bool reminder = true}) => ActivityEvent(
  id: 'e1',
  name: 'Corrida 10K',
  type: 'running',
  typeLabel: 'Corrida',
  startsAt: at,
  location: 'Marco Zero',
  reminderEnabled: reminder,
  attended: false,
);

void main() {
  // Quarta, 28/10/2026, 08:00.
  final now = DateTime(2026, 10, 28, 8);
  final today = DateTime(2026, 10, 28);

  test('meta com dias: um lembrete semanal por dia, no horário', () {
    final list = ActivityReminders.plan(
      plans: [_plan()],
      events: const [],
      today: today,
      now: now,
    );
    expect(list.map((e) => e.$2.weekday).toSet(), {1, 3, 5});
    expect(list.first.$2.title, 'Hora do treino');
    expect(list.first.$2.body, 'Academia · Boa Viagem · às 07:00');
    expect(list.every((e) => e.$2.hour == 7 && e.$2.minute == 0), isTrue);
  });

  test('sem horário, pausada ou lembrete desligado: nada agendado', () {
    for (final p in [
      _plan(time: null),
      _plan(active: false),
      _plan(reminder: false),
    ]) {
      expect(
        ActivityReminders.plan(
          plans: [p],
          events: const [],
          today: today,
          now: now,
        ),
        isEmpty,
      );
    }
  });

  test('evento: véspera às 19h e 2 horas antes', () {
    final list = ActivityReminders.plan(
      plans: const [],
      events: [_event(DateTime(2026, 11, 15, 7))],
      today: today,
      now: now,
    );
    expect(list, hasLength(2));
    expect(list[0].$1, DateTime(2026, 11, 14, 19));
    expect(list[0].$2.title, 'Amanhã: Corrida 10K');
    expect(list[1].$1, DateTime(2026, 11, 15, 5));
    expect(list[1].$2.date, DateTime(2026, 11, 15));
  });

  test('evento passado ou sem lembrete: nada agendado', () {
    expect(
      ActivityReminders.plan(
        plans: const [],
        events: [
          _event(DateTime(2026, 10, 27, 7)),
          _event(DateTime(2026, 11, 15, 7), reminder: false),
        ],
        today: today,
        now: now,
      ),
      isEmpty,
    );
  });
}
