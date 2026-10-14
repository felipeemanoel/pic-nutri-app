import '../../../core/utils/formatters.dart';

class WeightPoint {
  const WeightPoint(this.date, this.weightKg);

  final DateTime date;
  final double weightKg;

  static List<WeightPoint> listFrom(Object? json) =>
      (json as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (e) => WeightPoint(
              DateTime.parse(e['date'] as String),
              toDouble(e['weight_kg']) ?? 0,
            ),
          )
          .toList();
}

class GoalProgress {
  const GoalProgress({
    required this.goalWeightKg,
    required this.startWeightKg,
    required this.currentWeightKg,
    required this.remainingKg,
    required this.progressPercent,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) => GoalProgress(
    goalWeightKg: toDouble(json['goal_weight_kg']) ?? 0,
    startWeightKg: toDouble(json['start_weight_kg']) ?? 0,
    currentWeightKg: toDouble(json['current_weight_kg']) ?? 0,
    remainingKg: toDouble(json['remaining_kg']) ?? 0,
    progressPercent: toDouble(json['progress_percent']) ?? 0,
  );

  final double goalWeightKg;
  final double startWeightKg;
  final double currentWeightKg;
  final double remainingKg;
  final double progressPercent;
}

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
    this.notes,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'] as String,
    weightKg: toDouble(json['weight_kg']) ?? 0,
    measuredAt: DateTime.parse(json['measured_at'] as String).toLocal(),
    notes: json['notes'] as String?,
  );

  final String id;
  final double weightKg;
  final DateTime measuredAt;
  final String? notes;
}

abstract final class MeasurementTypes {
  static const labels = {
    'waist': 'Cintura',
    'hip': 'Quadril',
    'abdomen': 'Abdômen',
    'chest': 'Peitoral',
    'arm': 'Braço',
    'thigh': 'Coxa',
    'neck': 'Pescoço',
    'custom': 'Outra medida',
  };

  static String label(String type, [String? custom]) =>
      type == 'custom' ? (custom ?? 'Outra medida') : (labels[type] ?? type);
}

class Measurement {
  const Measurement({
    required this.id,
    required this.type,
    required this.valueCm,
    required this.measuredAt,
    this.label,
    this.notes,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    id: json['id'] as String,
    type: json['type'] as String,
    label: json['label'] as String?,
    valueCm: toDouble(json['value_cm']) ?? 0,
    measuredAt: DateTime.parse(json['measured_at'] as String).toLocal(),
    notes: json['notes'] as String?,
  );

  final String id;
  final String type;
  final String? label;
  final double valueCm;
  final DateTime measuredAt;
  final String? notes;

  String get displayName => MeasurementTypes.label(type, label);
}

class MeasurementChange {
  const MeasurementChange({
    required this.type,
    required this.lastCm,
    required this.changeCm,
    this.label,
  });

  factory MeasurementChange.fromJson(Map<String, dynamic> json) =>
      MeasurementChange(
        type: json['type'] as String,
        label: json['label'] as String?,
        lastCm: toDouble(json['last_cm']) ?? 0,
        changeCm: toDouble(json['change_cm']),
      );

  final String type;
  final String? label;
  final double lastCm;
  final double? changeCm;
}

class Bmi {
  const Bmi({
    required this.available,
    required this.note,
    this.value,
    this.category,
    this.reason,
  });

  factory Bmi.fromJson(Map<String, dynamic> json) => Bmi(
    available: json['available'] as bool? ?? false,
    value: toDouble(json['value']),
    category: json['category'] as String?,
    reason: json['reason'] as String?,
    note: json['note'] as String? ?? '',
  );

  final bool available;
  final double? value;
  final String? category;
  final String? reason;
  final String note;
}

/// Aplicação registrada no período (marcada no gráfico de peso).
class DoseMark {
  const DoseMark({required this.date, required this.medication, this.dose});

  factory DoseMark.fromJson(Map<String, dynamic> json) => DoseMark(
    date: DateTime.parse(json['date'] as String),
    medication: json['medication'] as String? ?? '',
    dose: json['dose'] as String?,
  );

  final DateTime date;
  final String medication;
  final String? dose;
}

/// Tendência dos próprios registros (continuação do ritmo, não promessa).
class WeightTrend {
  const WeightTrend({
    required this.available,
    this.message,
    this.weeklyChangeKg,
    this.direction,
    this.fastChange = false,
    this.fastChangeNote,
    this.goalWeightKg,
    this.goalDate,
    this.goalWeeks,
    this.note,
  });

  factory WeightTrend.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeightTrend(available: false);
    final goal = json['goal_estimate'] as Map<String, dynamic>?;
    return WeightTrend(
      available: json['available'] as bool? ?? false,
      message: json['message'] as String?,
      weeklyChangeKg: toDouble(json['weekly_change_kg']),
      direction: json['direction'] as String?,
      fastChange: json['fast_change'] as bool? ?? false,
      fastChangeNote: json['fast_change_note'] as String?,
      goalWeightKg: toDouble(goal?['goal_weight_kg']),
      goalDate: goal == null ? null : DateTime.parse(goal['date'] as String),
      goalWeeks: toInt(goal?['weeks']),
      note: json['note'] as String?,
    );
  }

  final bool available;

  /// Quando indisponível: o que falta registrar.
  final String? message;
  final double? weeklyChangeKg;

  /// down, up ou stable.
  final String? direction;
  final bool fastChange;
  final String? fastChangeNote;
  final double? goalWeightKg;
  final DateTime? goalDate;
  final int? goalWeeks;
  final String? note;
}

/// Foto de evolução (a imagem é carregada à parte, autenticada).
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.pose,
    required this.poseLabel,
    required this.takenAt,
    required this.localDate,
    this.notes,
    this.nearestWeightKg,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    final weight = json['nearest_weight'] as Map<String, dynamic>?;
    return ProgressPhoto(
      id: json['id'] as String,
      pose: json['pose'] as String,
      poseLabel: json['pose_label'] as String? ?? '',
      takenAt: DateTime.parse(json['taken_at'] as String).toLocal(),
      localDate: DateTime.parse(json['local_date'] as String),
      notes: json['notes'] as String?,
      nearestWeightKg: toDouble(weight?['weight_kg']),
    );
  }

  final String id;

  /// front, side, back ou other.
  final String pose;
  final String poseLabel;
  final DateTime takenAt;
  final DateTime localDate;
  final String? notes;

  /// Peso registrado no dia ou no mais próximo (até 7 dias).
  final double? nearestWeightKg;
}

abstract final class PhotoPoses {
  static const labels = {'front': 'Frente', 'side': 'Lado', 'back': 'Costas', 'other': 'Outra'};
}

class BodyProgress {
  const BodyProgress({
    required this.series,
    required this.changeKg,
    required this.previousChangeKg,
    required this.goal,
    required this.bmi,
    required this.measurements,
    this.trend = const WeightTrend(available: false),
    this.doses = const [],
  });

  factory BodyProgress.fromJson(Map<String, dynamic> json) {
    final weight = json['weight'] as Map<String, dynamic>;
    final goal = json['goal'] as Map<String, dynamic>?;
    return BodyProgress(
      series: WeightPoint.listFrom(weight['series']),
      changeKg: toDouble(weight['change_kg']),
      previousChangeKg: toDouble(weight['previous_period_change_kg']),
      goal: goal == null ? null : GoalProgress.fromJson(goal),
      bmi: Bmi.fromJson(json['bmi'] as Map<String, dynamic>),
      measurements: (json['measurements'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MeasurementChange.fromJson)
          .toList(),
      trend: WeightTrend.fromJson(json['trend'] as Map<String, dynamic>?),
      doses: (json['doses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(DoseMark.fromJson)
          .toList(),
    );
  }

  final List<WeightPoint> series;
  final double? changeKg;
  final double? previousChangeKg;
  final GoalProgress? goal;
  final Bmi bmi;
  final List<MeasurementChange> measurements;
  final WeightTrend trend;
  final List<DoseMark> doses;
}
