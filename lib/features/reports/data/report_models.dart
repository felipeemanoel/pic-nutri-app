import '../../../core/utils/formatters.dart';

class DayLog {
  const DayLog({
    required this.date,
    required this.meals,
    required this.energyKcal,
    required this.proteinG,
    required this.waterMl,
    required this.logged,
    this.caloriesMet,
    this.proteinMet,
    required this.waterMet,
  });

  factory DayLog.fromJson(Map<String, dynamic> json) => DayLog(
    date: DateTime.parse(json['date'] as String),
    meals: toInt(json['meals']) ?? 0,
    energyKcal: toDouble(json['energy_kcal']) ?? 0,
    proteinG: toDouble(json['protein_g']) ?? 0,
    waterMl: toInt(json['water_ml']) ?? 0,
    logged: json['logged'] as bool? ?? false,
    caloriesMet: json['calories_met'] as bool?,
    proteinMet: json['protein_met'] as bool?,
    waterMet: json['water_met'] as bool? ?? false,
  );

  final DateTime date;
  final int meals;
  final double energyKcal;
  final double proteinG;
  final int waterMl;
  final bool logged;

  /// `null` quando não há meta ou registro no dia.
  final bool? caloriesMet;
  final bool? proteinMet;
  final bool waterMet;
}

class PeriodSummary {
  const PeriodSummary({
    required this.daysLogged,
    required this.daysCaloriesMet,
    required this.daysProteinMet,
    required this.daysWaterMet,
    this.avgEnergyKcal,
    this.avgProteinG,
    this.avgCarbsG,
    this.avgFatG,
    this.avgWaterMl,
  });

  factory PeriodSummary.fromJson(Map<String, dynamic> json) => PeriodSummary(
    daysLogged: toInt(json['days_logged']) ?? 0,
    avgEnergyKcal: toDouble(json['avg_energy_kcal']),
    avgProteinG: toDouble(json['avg_protein_g']),
    avgCarbsG: toDouble(json['avg_carbs_g']),
    avgFatG: toDouble(json['avg_fat_g']),
    avgWaterMl: toInt(json['avg_water_ml']),
    daysCaloriesMet: toInt(json['days_calories_met']) ?? 0,
    daysProteinMet: toInt(json['days_protein_met']) ?? 0,
    daysWaterMet: toInt(json['days_water_met']) ?? 0,
  );

  final int daysLogged;
  final double? avgEnergyKcal;
  final double? avgProteinG;
  final double? avgCarbsG;
  final double? avgFatG;
  final int? avgWaterMl;
  final int daysCaloriesMet;
  final int daysProteinMet;
  final int daysWaterMet;
}

class PeriodReport {
  const PeriodReport({
    required this.period,
    required this.from,
    required this.to,
    required this.daysElapsed,
    required this.summary,
    required this.previous,
    required this.days,
    required this.mealsByType,
    this.goalKcal,
    this.goalProteinG,
    this.goalWaterMl,
    this.weightChangeKg,
    this.weightLastKg,
    this.inProgress = false,
  });

  factory PeriodReport.fromJson(Map<String, dynamic> json) {
    final goals = json['goals'] as Map<String, dynamic>? ?? const {};
    final weight = json['weight'] as Map<String, dynamic>?;
    return PeriodReport(
      period: json['period'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      daysElapsed: toInt(json['days_elapsed']) ?? 0,
      summary: PeriodSummary.fromJson(json['summary'] as Map<String, dynamic>),
      previous: PeriodSummary.fromJson(json['previous'] as Map<String, dynamic>),
      days: (json['days'] as List<dynamic>).cast<Map<String, dynamic>>().map(DayLog.fromJson).toList(),
      mealsByType: [
        for (final m in (json['meals_by_type'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
          (m['label'] as String, toInt(m['count']) ?? 0),
      ],
      goalKcal: toInt(goals['energy_kcal']),
      goalProteinG: toInt(goals['protein_g']),
      goalWaterMl: toInt(goals['water_ml']),
      weightChangeKg: toDouble(weight?['change_kg']),
      weightLastKg: toDouble(weight?['last_kg']),
      inProgress: json['in_progress'] as bool? ?? false,
    );
  }

  /// `week` ou `month`.
  final String period;
  final DateTime from;
  final DateTime to;

  /// Dias do período até hoje.
  final int daysElapsed;
  final PeriodSummary summary;
  final PeriodSummary previous;
  final List<DayLog> days;
  final List<(String, int)> mealsByType;
  final int? goalKcal;
  final int? goalProteinG;
  final int? goalWaterMl;
  final double? weightChangeKg;
  final double? weightLastKg;

  /// Período em andamento (inclui hoje) ou já concluído.
  final bool inProgress;
}
