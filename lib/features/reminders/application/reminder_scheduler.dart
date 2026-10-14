import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications.dart';
import '../../auth/application/session_controller.dart';
import '../../home/data/dashboard.dart';
import '../../home/data/dashboard_repository.dart';
import '../data/reminder_models.dart';
import '../data/reminder_repository.dart';

/// Mantém as notificações do aparelho iguais aos lembretes salvos na conta.
///
/// Avisos condicionais (meta de água e registro do dia) são agendados um a um
/// para os próximos 7 dias; o de hoje é omitido quando a meta já foi atingida.
/// O app reagenda ao abrir e após cada registro de água ou refeição.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  static const conditionalTypes = {'water_goal', 'daily_log'};

  Future<void> sync() async {
    final notifications = _ref.read(localNotificationsProvider);
    final profile = _ref.read(currentAccountProvider)?.profile;
    if (profile == null || !profile.notificationsEnabled) {
      await notifications.cancelAll();
      return;
    }

    final List<Reminder> reminders;
    try {
      reminders = await _ref.read(reminderRepositoryProvider).list();
    } on Object {
      return;
    }
    final active = reminders.where((r) => r.enabled).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Dashboard? todayStatus;
    if (active.any((r) => conditionalTypes.contains(r.type))) {
      try {
        todayStatus = await _ref.read(dashboardRepositoryProvider).load(today);
      } on Object {
        todayStatus = null; // Sem status: agenda normalmente.
      }
    }

    final status = todayStatus;
    bool metToday(String type) => switch (type) {
      'water_goal' => status != null && status.waterTotalMl >= status.waterGoalMl,
      'daily_log' => status != null && status.nutrition.mealsCount > 0,
      _ => false,
    };

    await notifications.replaceAll([
      for (final r in active) ...[
        if (conditionalTypes.contains(r.type))
          for (var offset = 0; offset < 7; offset++)
            if (r.days.contains(today.add(Duration(days: offset)).weekday) && !(offset == 0 && metToday(r.type)))
              WeeklyNotification(
                id: notificationId(r.id, today.add(Duration(days: offset)).weekday),
                title: r.displayTitle,
                body: r.body,
                weekday: today.add(Duration(days: offset)).weekday,
                hour: r.hour,
                minute: r.minute,
                date: today.add(Duration(days: offset)),
                payload: r.route,
              ),
        if (!conditionalTypes.contains(r.type))
          for (final day in r.days)
            WeeklyNotification(
              id: notificationId(r.id, day),
              title: r.displayTitle,
              body: r.body,
              weekday: day,
              hour: r.hour,
              minute: r.minute,
              payload: r.route,
            ),
      ],
    ], timezone: profile.timezone);
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);
