import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications.dart';
import '../../activity/application/activity_reminders.dart';
import '../../activity/data/activity_models.dart';
import '../../activity/data/activity_repository.dart';
import '../../auth/application/session_controller.dart';
import '../../home/data/dashboard.dart';
import '../../home/data/dashboard_repository.dart';
import '../../notifications/data/notification_models.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/reminder_models.dart';
import '../data/reminder_repository.dart';

/// Mantém as notificações do aparelho iguais aos lembretes salvos na conta.
///
/// - Respeita a chave geral do perfil, as categorias desligadas e o período
///   de silêncio (horários dentro dele não são agendados).
/// - Lembretes de todos os dias viram uma notificação diária por horário;
///   os demais, uma por dia da semana.
/// - Avisos condicionais (meta de água, registro do dia, metas) são agendados
///   um a um para os próximos 7 dias; o de hoje é omitido quando a meta já
///   foi cumprida. O app reagenda ao abrir, ao voltar ao app e após cada
///   registro de água ou refeição.
/// - O iOS aceita até 64 agendamentos: ficam os mais próximos.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

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
      return; // Sem rede: mantém o que já está agendado.
    }
    NotificationPreferences? preferences;
    try {
      preferences = await _ref
          .read(notificationRepositoryProvider)
          .preferences();
    } on Object {
      preferences = null; // Sem preferências: tudo ligado, sem silêncio.
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = reminders.where((r) => r.enabled).toList();

    Dashboard? todayStatus;
    if (active.any((r) => ReminderLabels.conditionalTypes.contains(r.type))) {
      try {
        todayStatus = await _ref.read(dashboardRepositoryProvider).load(today);
      } on Object {
        todayStatus = null; // Sem status: agenda normalmente.
      }
    }

    // Atividade física: horários das metas e eventos (sem rede, fica sem).
    var activityPlans = const <ActivityPlan>[];
    var activityEvents = const <ActivityEvent>[];
    try {
      final repo = _ref.read(activityRepositoryProvider);
      activityPlans = await repo.plans();
      activityEvents = await repo.events();
    } on Object {
      // Mantém só os lembretes da conta.
    }

    await notifications.replaceAll(
      plan(
        active,
        preferences: preferences,
        today: today,
        now: now,
        status: todayStatus,
        extra: ActivityReminders.plan(
          plans: activityPlans,
          events: activityEvents,
          today: today,
          now: now,
          preferences: preferences,
        ),
      ),
      timezone: profile.timezone,
    );
  }

  /// Agendamentos para os lembretes ativos (função pura, testada isoladamente).
  static List<WeeklyNotification> plan(
    List<Reminder> reminders, {
    required DateTime today,
    required DateTime now,
    NotificationPreferences? preferences,
    Dashboard? status,
    List<(DateTime, WeeklyNotification)> extra = const [],
  }) {
    final waterMet =
        status != null && status.waterTotalMl >= status.waterGoalMl;
    final mealsLogged = status != null && status.nutrition.mealsCount > 0;
    bool metToday(String type) => switch (type) {
      'water_goal' => waterMet,
      'daily_log' => mealsLogged,
      'daily_goals' => waterMet && mealsLogged,
      _ => false,
    };

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

    for (final r in reminders) {
      if (!r.enabled || !(preferences?.allows(r.category) ?? true)) continue;
      final times = r.times;
      for (var slot = 0; slot < times.length; slot++) {
        final (hour, minute) = times[slot];
        if (preferences?.isQuiet(hour, minute) ?? false) continue;

        WeeklyNotification make({
          required int id,
          int? weekday,
          DateTime? date,
        }) => WeeklyNotification(
          id: id,
          title: r.notificationTitle,
          body: r.body,
          weekday: weekday,
          hour: hour,
          minute: minute,
          date: date,
          payload: r.route,
        );

        if (ReminderLabels.conditionalTypes.contains(r.type)) {
          for (var offset = 0; offset < 7; offset++) {
            final day = today.add(Duration(days: offset));
            if (!r.days.contains(day.weekday) ||
                (offset == 0 && metToday(r.type))) {
              continue;
            }
            final at = DateTime(day.year, day.month, day.day, hour, minute);
            if (!at.isAfter(now)) continue;
            result.add((
              at,
              make(
                id: notificationId(r.id, day.weekday, slot),
                weekday: day.weekday,
                date: day,
              ),
            ));
          }
        } else if (r.days.length == 7) {
          result.add((
            nextAt(null, hour, minute),
            make(id: notificationId(r.id, 0, slot)),
          ));
        } else {
          for (final day in r.days) {
            result.add((
              nextAt(day, hour, minute),
              make(id: notificationId(r.id, day, slot), weekday: day),
            ));
          }
        }
      }
    }

    result
      ..addAll(extra)
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, n) in result.take(LocalNotifications.maxScheduled)) n,
    ];
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);
