import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/engagement/data/engagement_repository.dart';
import '../../features/food/data/food_repository.dart';
import '../../features/home/data/dashboard_repository.dart';
import '../../features/medication/data/medication_repository.dart';
import '../../features/progress/data/body_repository.dart';
import '../../features/reminders/application/reminder_scheduler.dart';
import '../../features/reports/data/report_repository.dart';
import '../../features/water/data/water_repository.dart';

/// Recarrega os dados afetados após uma alteração, mantendo painel, diário e
/// gráficos consistentes com o que foi gravado na API.
abstract final class Refresh {
  static void nutrition(WidgetRef ref) {
    ref
      ..invalidate(mealsOnDayProvider)
      ..invalidate(nutritionSummaryProvider)
      ..invalidate(dashboardProvider)
      ..invalidate(engagementProvider)
      ..invalidate(periodReportProvider)
      ..invalidate(celebrationsProvider);
    _resyncReminders(ref);
  }

  static void water(WidgetRef ref) {
    ref
      ..invalidate(waterDayProvider)
      ..invalidate(waterHistoryProvider)
      ..invalidate(dashboardProvider)
      ..invalidate(engagementProvider)
      ..invalidate(periodReportProvider)
      ..invalidate(celebrationsProvider);
    _resyncReminders(ref);
  }

  static void medication(WidgetRef ref) {
    ref
      ..invalidate(medicationsProvider)
      ..invalidate(recentDosesProvider)
      ..invalidate(dashboardProvider);
  }

  static void body(WidgetRef ref) {
    ref
      ..invalidate(bodyProgressProvider)
      ..invalidate(weightEntriesProvider)
      ..invalidate(measurementsProvider)
      ..invalidate(dashboardProvider)
      ..invalidate(engagementProvider);
  }

  /// Avisos condicionais (meta de água, registro do dia) dependem do que foi
  /// registrado hoje: reagenda em segundo plano, sem bloquear a tela.
  static void _resyncReminders(WidgetRef ref) =>
      unawaited(ref.read(reminderSchedulerProvider).sync().catchError((Object _) {}));
}
