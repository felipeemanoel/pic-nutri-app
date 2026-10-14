import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/reminders/data/reminder_models.dart';

void main() {
  test('lê o lembrete e monta horário e texto sem orientação de dose', () {
    final reminder = Reminder.fromJson({
      'id': '01JREMINDER',
      'type': 'medication',
      'title': null,
      'display_title': 'Registrar aplicação do medicamento',
      'time': '08:30',
      'days': [1, 4],
      'enabled': true,
      'medication_id': null,
    });

    expect(reminder.hour, 8);
    expect(reminder.minute, 30);
    expect(reminder.body, isNot(contains('dose')));
    expect(ReminderLabels.days(reminder.days), 'Seg, Qui');
    expect(ReminderLabels.days([1, 2, 3, 4, 5]), 'Dias úteis');
  });

  test('ids de notificação são estáveis e distintos por dia', () {
    final a = notificationId('01JREMINDER', 1);
    expect(notificationId('01JREMINDER', 1), a);
    expect(notificationId('01JREMINDER', 2), isNot(a));
    expect(notificationId('01JOUTRO', 1), isNot(a));
    expect(a, lessThan(0x7FFFFFFF));
  });
}
