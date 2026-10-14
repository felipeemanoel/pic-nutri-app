import '../../../core/utils/formatters.dart';

/// Sugestão de metas calculada pela API (referência ajustável).
class GoalSuggestion {
  const GoalSuggestion({
    required this.available,
    required this.reason,
    required this.method,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.tdeeKcal,
    required this.notes,
  });

  factory GoalSuggestion.fromJson(Map<String, dynamic> json) => GoalSuggestion(
    available: json['available'] as bool? ?? false,
    reason: json['reason'] as String?,
    method: json['method'] as String? ?? '',
    caloriesKcal: toInt(json['calories_kcal']),
    proteinG: toInt(json['protein_g']),
    carbsG: toInt(json['carbs_g']),
    fatG: toInt(json['fat_g']),
    waterMl: toInt(json['water_ml']),
    tdeeKcal: toInt(json['tdee_kcal']),
    notes: (json['notes'] as List<dynamic>? ?? []).whereType<String>().toList(),
  );

  final bool available;
  final String? reason;
  final String method;
  final int? caloriesKcal;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final int? waterMl;
  final int? tdeeKcal;
  final List<String> notes;
}
