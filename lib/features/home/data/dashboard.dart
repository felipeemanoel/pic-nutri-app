import '../../../app/features.dart';
import '../../../core/utils/formatters.dart';
import '../../food/data/nutrition_models.dart';
import '../../progress/data/body_models.dart';

/// Indicadores do dia, montados pela API a partir dos registros reais.
class Dashboard {
  const Dashboard({
    required this.date,
    required this.isToday,
    required this.nutrition,
    required this.waterTotalMl,
    required this.waterGoalMl,
    required this.weight,
    required this.goal,
    required this.medicationTrackingEnabled,
    this.lastDose,
    this.nextReminders = const [],
    this.pendingMeals = const [],
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final water = json['water'] as Map<String, dynamic>? ?? const {};
    final weight = json['weight'] as Map<String, dynamic>?;
    final goal = json['goal'] as Map<String, dynamic>?;
    final medication = json['medication'] as Map<String, dynamic>?;
    final lastDose = medication?['last_dose'] as Map<String, dynamic>?;
    return Dashboard(
      date: DateTime.parse(json['date'] as String),
      isToday: json['is_today'] as bool? ?? false,
      nutrition: NutritionSummary.fromJson(
        json['nutrition'] as Map<String, dynamic>,
      ),
      waterTotalMl: toInt(water['total_ml']) ?? 0,
      waterGoalMl: toInt(water['goal_ml']) ?? 2000,
      weight: weight == null ? null : WeightSnapshot.fromJson(weight),
      goal: goal == null ? null : GoalProgress.fromJson(goal),
      medicationTrackingEnabled:
          AppFeatures.medical && (json['medication_tracking_enabled'] as bool? ?? false),
      pendingMeals: [
        for (final m in (json['pending_meals'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
          PendingMeal(
            mealType: m['meal_type'] as String,
            label: m['label'] as String,
            late: m['status'] == 'late',
          ),
      ],
      nextReminders: (json['next_reminders'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (r) => UpcomingReminder(
              title: r['title'] as String,
              at: DateTime.parse(r['at'] as String).toLocal(),
            ),
          )
          .toList(),
      lastDose: lastDose == null
          ? null
          : LastDose(
              medicationName: lastDose['medication_name'] as String,
              takenAt: DateTime.parse(lastDose['taken_at'] as String).toLocal(),
            ),
    );
  }

  final DateTime date;
  final bool isToday;
  final NutritionSummary nutrition;
  final int waterTotalMl;
  final int waterGoalMl;
  final WeightSnapshot? weight;
  final GoalProgress? goal;
  final bool medicationTrackingEnabled;

  /// Última aplicação registrada (só com o acompanhamento ativo).
  final LastDose? lastDose;

  /// Próximos lembretes ativos (calculados pela API).
  final List<UpcomingReminder> nextReminders;

  /// Refeições que o usuário costuma fazer e ainda não registrou no dia.
  final List<PendingMeal> pendingMeals;
}

class PendingMeal {
  const PendingMeal({required this.mealType, required this.label, required this.late});

  final String mealType;
  final String label;

  /// O horário habitual já passou (informativo, sem cobrança).
  final bool late;
}

class UpcomingReminder {
  const UpcomingReminder({required this.title, required this.at});

  final String title;
  final DateTime at;
}

class LastDose {
  const LastDose({required this.medicationName, required this.takenAt});

  final String medicationName;
  final DateTime takenAt;
}

class WeightSnapshot {
  const WeightSnapshot({
    required this.latestKg,
    required this.latestDate,
    required this.change30dKg,
    required this.series,
  });

  factory WeightSnapshot.fromJson(Map<String, dynamic> json) => WeightSnapshot(
    latestKg: toDouble(json['latest_kg']) ?? 0,
    latestDate: DateTime.parse(json['latest_date'] as String),
    change30dKg: toDouble(json['change_30d_kg']),
    series: WeightPoint.listFrom(json['series_30d']),
  );

  final double latestKg;
  final DateTime latestDate;
  final double? change30dKg;
  final List<WeightPoint> series;
}
