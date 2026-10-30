import '../../../app/routes.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/utils/formatters.dart';
import '../../notifications/data/notification_models.dart';
import '../../reminders/data/reminder_models.dart';
import '../data/activity_models.dart';

/// Lembretes locais da atividade física: o horário de cada meta (nos dias
/// combinados) e os eventos (véspera às 19h e 2 horas antes). Seguem a
/// categoria "Peso e acompanhamento" e o período de silêncio.
abstract final class ActivityReminders {
  static const category = 'progress';
  static const eveningBefore = 19;
  static const hoursBefore = 2;

  /// Agendamentos com o próximo disparo de cada um (para ordenar).
  static List<(DateTime, WeeklyNotification)> plan({
    required List<ActivityPlan> plans,
    required List<ActivityEvent> events,
    required DateTime today,
    required DateTime now,
    NotificationPreferences? preferences,
  }) {
    if (!(preferences?.allows(category) ?? true)) return const [];
    bool quiet(int h, int m) => preferences?.isQuiet(h, m) ?? false;
    final result = <(DateTime, WeeklyNotification)>[];

    DateTime nextAt(int? weekday, int hour, int minute) {
      for (var offset = 0; offset <= 7; offset++) {
        final day = today.add(Duration(days: offset));
        final at = DateTime(day.year, day.month, day.day, hour, minute);
        if ((weekday == null || day.weekday == weekday) && at.isAfter(now)) {
          return at;
        }
      }
      return today.add(const Duration(days: 8));
    }

    for (final p in plans) {
      final time = p.time;
      if (!p.isActive || !p.reminderEnabled || time == null) continue;
      final hour = int.parse(time.substring(0, 2));
      final minute = int.parse(time.substring(3, 5));
      if (quiet(hour, minute)) continue;
      final body = [
        p.displayName,
        if (p.location?.isNotEmpty ?? false) p.location!,
        'às $time',
      ].join(' · ');
      WeeklyNotification make(int? weekday) => WeeklyNotification(
        id: notificationId('activity:${p.id}', weekday ?? 0),
        title: 'Hora do treino',
        body: body,
        weekday: weekday,
        hour: hour,
        minute: minute,
        payload: AppRoutes.activity,
      );
      if (p.days.isEmpty || p.days.length == 7) {
        result.add((nextAt(null, hour, minute), make(null)));
      } else {
        for (final d in p.days) {
          result.add((nextAt(d, hour, minute), make(d)));
        }
      }
    }

    for (final e in events) {
      if (!e.reminderEnabled || !e.startsAt.isAfter(now)) continue;
      final place = e.location?.isNotEmpty ?? false ? ' · ${e.location}' : '';
      final day = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      final eve = DateTime(day.year, day.month, day.day - 1, eveningBefore);
      if (eve.isAfter(now) && !quiet(eve.hour, eve.minute)) {
        result.add((
          eve,
          WeeklyNotification(
            id: notificationId('event-eve:${e.id}', 0),
            title: 'Amanhã: ${e.name}',
            body: 'Às ${Fmt.time(e.startsAt)}$place. Separe o que vai precisar.',
            weekday: null,
            hour: eve.hour,
            minute: eve.minute,
            date: eve,
            payload: AppRoutes.activity,
          ),
        ));
      }
      final soon = e.startsAt.subtract(const Duration(hours: hoursBefore));
      if (soon.isAfter(now) && !quiet(soon.hour, soon.minute)) {
        result.add((
          soon,
          WeeklyNotification(
            id: notificationId('event-soon:${e.id}', 0),
            title: 'Daqui a 2 horas: ${e.name}',
            body: 'Começa às ${Fmt.time(e.startsAt)}$place. Bom evento!',
            weekday: null,
            hour: soon.hour,
            minute: soon.minute,
            date: DateTime(soon.year, soon.month, soon.day),
            payload: AppRoutes.activity,
          ),
        ));
      }
    }
    return result;
  }
}
