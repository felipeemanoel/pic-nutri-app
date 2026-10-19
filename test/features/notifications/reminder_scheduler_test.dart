import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/home/data/dashboard.dart';
import 'package:picnutri/features/notifications/data/notification_models.dart';
import 'package:picnutri/features/reminders/application/reminder_scheduler.dart';
import 'package:picnutri/features/reminders/data/reminder_models.dart';

Reminder _reminder(
  String type, {
  String id = '01JREM',
  String time = '08:00',
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  int? interval,
  String? end,
}) => Reminder.fromJson({
  'id': id,
  'type': type,
  'title': null,
  'display_title': ReminderLabels.types[type],
  'time': time,
  'days': days,
  'enabled': true,
  'interval_minutes': interval,
  'end_time': end,
});

NotificationPreferences _prefs({
  Map<String, bool> off = const {},
  String? quietStart,
  String? quietEnd,
}) => NotificationPreferences(
  categories: [
    for (final key in ['water', 'meals', 'meal_log', 'progress', 'goals'])
      NotificationCategoryPref(
        key: key,
        label: key,
        enabled: !(off[key] ?? false),
        localReminders: true,
      ),
  ],
  quietHoursEnabled: quietStart != null,
  quietStart: quietStart,
  quietEnd: quietEnd,
);

Dashboard _status({int water = 0, int meals = 0}) => Dashboard.fromJson({
  'date': '2026-10-19',
  'is_today': true,
  'nutrition': {
    'meals_count': meals,
    'totals': {'energy_kcal': 0, 'protein_g': 0, 'carbs_g': 0, 'fat_g': 0},
    'goals': {
      'energy_kcal': null,
      'protein_g': null,
      'carbs_g': null,
      'fat_g': null,
    },
    'energy_remaining_kcal': null,
  },
  'water': {'total_ml': water, 'goal_ml': 2000},
  'weight': null,
  'goal': null,
  'medication_tracking_enabled': false,
});

void main() {
  // Segunda, 19/10/2026, 07:00.
  final now = DateTime(2026, 10, 19, 7);
  final today = DateTime(2026, 10, 19);

  test(
    'lembrete de todos os dias com repetição vira um aviso diário por horário',
    () {
      final plan = ReminderScheduler.plan(
        [_reminder('water', time: '08:00', interval: 120, end: '14:00')],
        today: today,
        now: now,
      );

      expect(plan.map((n) => '${n.hour}:${n.minute}').toList(), [
        '8:0',
        '10:0',
        '12:0',
        '14:0',
      ]);
      expect(plan.every((n) => n.weekday == null && n.date == null), isTrue);
      expect(plan.map((n) => n.id).toSet(), hasLength(4));
    },
  );

  test('respeita categoria desligada e período de silêncio', () {
    final reminders = [
      _reminder('water', id: 'A', time: '08:00'),
      _reminder('weigh_in', id: 'B', time: '23:00', days: [1, 3]),
      _reminder('weigh_in', id: 'C', time: '09:00', days: [1, 3]),
    ];

    final plan = ReminderScheduler.plan(
      reminders,
      today: today,
      now: now,
      preferences: _prefs(
        off: {'water': true},
        quietStart: '22:00',
        quietEnd: '07:00',
      ),
    );

    expect(plan.map((n) => n.title).toSet(), {'Pesagem'});
    expect(plan.map((n) => n.weekday).toList(), [1, 3]);
    expect(plan.every((n) => n.hour == 9), isTrue);
  });

  test('aviso condicional some hoje quando a meta já foi cumprida', () {
    final reminders = [_reminder('water_goal', time: '18:00')];

    final pending = ReminderScheduler.plan(
      reminders,
      today: today,
      now: now,
      status: _status(water: 500),
    );
    final met = ReminderScheduler.plan(
      reminders,
      today: today,
      now: now,
      status: _status(water: 2000),
    );

    expect(pending.first.date, today);
    expect(met.first.date, today.add(const Duration(days: 1)));
    expect(pending, hasLength(7));
    expect(met, hasLength(6));
  });

  test('medicamento usa título neutro e o total respeita o limite do iOS', () {
    final plan = ReminderScheduler.plan(
      [
        _reminder('medication', id: 'M', days: [2]),
        for (var i = 0; i < 12; i++)
          _reminder(
            'water',
            id: 'W$i',
            time: '06:00',
            interval: 30,
            end: '23:30',
          ),
      ],
      today: today,
      now: now,
    );

    expect(plan, hasLength(60));
    final medication = ReminderScheduler.plan(
      [
        _reminder('medication', days: [2]),
      ],
      today: today,
      now: now,
    ).single;
    expect(medication.title, 'Lembrete do PicNutri');
    expect(medication.body, isNot(contains('medicamento')));
  });

  test('ids distintos por dia e por horário do dia', () {
    final a = notificationId('01JREMINDER', 1);
    expect(notificationId('01JREMINDER', 1, 1), isNot(a));
    expect(notificationId('01JREMINDER', 0, 23), lessThan(0x7FFFFFFF));
  });
}
