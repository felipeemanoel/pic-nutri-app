import '../data/activity_models.dart';

/// Contas simples da atividade física, feitas no aparelho.
abstract final class ActivityMath {
  static const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  /// Gasto estimado (kcal) = MET × ajuste da intensidade × peso × horas.
  /// Nulo sem peso ou sem a modalidade. É uma referência, não uma medida.
  static int? estimatedKcal({
    required ActivityTypeOption? type,
    required int durationMin,
    double? weightKg,
    IntensityOption? intensity,
  }) {
    if (type == null || weightKg == null || weightKg <= 0 || durationMin <= 0) {
      return null;
    }
    final factor = intensity?.factor ?? 1;
    return (type.met * factor * weightKg * durationMin / 60).round();
  }

  /// Ritmo em min/km ("5:48 /km"), quando há distância.
  static String? pace(int durationMin, double? distanceKm) {
    if (distanceKm == null || distanceKm <= 0 || durationMin <= 0) return null;
    final secondsPerKm = (durationMin * 60 / distanceKm).round();
    final m = secondsPerKm ~/ 60;
    final s = (secondsPerKm % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  /// "1h 15min", "45min".
  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  /// "3x por semana · seg, qua, sex · 07:00".
  static String schedule(ActivityPlan plan) {
    final parts = <String>['${plan.timesPerWeek}x por semana'];
    if (plan.days.isNotEmpty && plan.days.length < 7) {
      parts.add([for (final d in plan.days) _weekdays[d - 1]].join(', '));
    } else if (plan.days.length == 7) {
      parts.add('todos os dias');
    }
    if (plan.time != null) parts.add(plan.time!);
    return parts.join(' · ');
  }

  /// Próximo horário combinado da meta a partir de [now] (dias e horário).
  static DateTime? nextSlot(ActivityPlan plan, DateTime now) {
    final time = plan.time;
    if (time == null) return null;
    final h = int.parse(time.substring(0, 2));
    final m = int.parse(time.substring(3, 5));
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset, h, m);
      final allowed = plan.days.isEmpty || plan.days.contains(day.weekday);
      if (allowed && day.isAfter(now)) return day;
    }
    return null;
  }
}
