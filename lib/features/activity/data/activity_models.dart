import '../../../core/utils/formatters.dart';

/// Modalidade de atividade (a lista vem da API; o app tem ícones próprios).
class ActivityTypeOption {
  const ActivityTypeOption({
    required this.value,
    required this.label,
    required this.met,
    required this.supportsDistance,
  });

  factory ActivityTypeOption.fromJson(Map<String, dynamic> json) =>
      ActivityTypeOption(
        value: json['value'] as String,
        label: json['label'] as String,
        met: toDouble(json['met']) ?? 4,
        supportsDistance: json['supports_distance'] as bool? ?? false,
      );

  final String value;
  final String label;

  /// Gasto de referência (MET) em intensidade moderada.
  final double met;
  final bool supportsDistance;
}

class IntensityOption {
  const IntensityOption({
    required this.value,
    required this.label,
    required this.factor,
  });

  factory IntensityOption.fromJson(Map<String, dynamic> json) =>
      IntensityOption(
        value: json['value'] as String,
        label: json['label'] as String,
        factor: toDouble(json['factor']) ?? 1,
      );

  final String value;
  final String label;
  final double factor;
}

class ActivityOptions {
  const ActivityOptions({required this.types, required this.intensities});

  factory ActivityOptions.fromJson(Map<String, dynamic> json) =>
      ActivityOptions(
        types: [
          for (final t in (json['types'] as List<dynamic>? ?? const []))
            ActivityTypeOption.fromJson(t as Map<String, dynamic>),
        ],
        intensities: [
          for (final i in (json['intensities'] as List<dynamic>? ?? const []))
            IntensityOption.fromJson(i as Map<String, dynamic>),
        ],
      );

  final List<ActivityTypeOption> types;
  final List<IntensityOption> intensities;

  ActivityTypeOption? type(String value) =>
      types.where((t) => t.value == value).firstOrNull;

  IntensityOption? intensity(String? value) =>
      intensities.where((i) => i.value == value).firstOrNull;
}

/// Meta semanal ("Musculação na Academia X, 3x por semana às 7h").
class ActivityPlan {
  const ActivityPlan({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.timesPerWeek,
    required this.days,
    required this.reminderEnabled,
    required this.isActive,
    this.title,
    this.location,
    this.time,
    this.durationMin,
    this.doneThisWeek = 0,
    this.doneDays = const [],
  });

  factory ActivityPlan.fromJson(Map<String, dynamic> json) => ActivityPlan(
    id: json['id'] as String,
    type: json['type'] as String,
    typeLabel: json['type_label'] as String? ?? '',
    title: json['title'] as String?,
    location: json['location'] as String?,
    timesPerWeek: toInt(json['times_per_week']) ?? 1,
    days: [
      for (final d in (json['days'] as List<dynamic>? ?? const [])) toInt(d)!,
    ],
    time: json['time'] as String?,
    durationMin: toInt(json['duration_min']),
    reminderEnabled: json['reminder_enabled'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
    doneThisWeek: toInt(json['done_this_week']) ?? 0,
    doneDays: [
      for (final d in (json['done_days'] as List<dynamic>? ?? const []))
        toInt(d)!,
    ],
  );

  final String id;
  final String type;
  final String typeLabel;
  final String? title;
  final String? location;
  final int timesPerWeek;

  /// Dias combinados (1 = segunda ... 7 = domingo); vazio = qualquer dia.
  final List<int> days;

  /// "HH:MM".
  final String? time;
  final int? durationMin;
  final bool reminderEnabled;
  final bool isActive;

  /// Só no resumo da semana.
  final int doneThisWeek;
  final List<int> doneDays;

  bool get goalMet => doneThisWeek >= timesPerWeek;

  /// Nome exibido: o título informado ou a modalidade.
  String get displayName => title?.isNotEmpty ?? false ? title! : typeLabel;
}

/// Atividade realizada.
class ActivitySession {
  const ActivitySession({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.performedAt,
    required this.durationMin,
    this.planId,
    this.eventId,
    this.title,
    this.intensity,
    this.distanceKm,
    this.notes,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) =>
      ActivitySession(
        id: json['id'] as String,
        planId: json['plan_id'] as String?,
        eventId: json['event_id'] as String?,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String? ?? '',
        title: json['title'] as String?,
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
        durationMin: toInt(json['duration_min']) ?? 0,
        intensity: json['intensity'] as String?,
        distanceKm: toDouble(json['distance_km']),
        notes: json['notes'] as String?,
      );

  final String id;
  final String? planId;
  final String? eventId;
  final String type;
  final String typeLabel;
  final String? title;
  final DateTime performedAt;
  final int durationMin;
  final String? intensity;
  final double? distanceKm;
  final String? notes;

  String get displayName => title?.isNotEmpty ?? false ? title! : typeLabel;
}

/// Evento em que a pessoa vai (corrida de rua, passeio, aulão...).
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.startsAt,
    required this.reminderEnabled,
    required this.attended,
    this.location,
    this.distanceKm,
    this.url,
    this.notes,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    typeLabel: json['type_label'] as String? ?? '',
    startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
    location: json['location'] as String?,
    distanceKm: toDouble(json['distance_km']),
    url: json['url'] as String?,
    notes: json['notes'] as String?,
    reminderEnabled: json['reminder_enabled'] as bool? ?? true,
    attended: json['attended'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String type;
  final String typeLabel;
  final DateTime startsAt;
  final String? location;
  final double? distanceKm;
  final String? url;
  final String? notes;
  final bool reminderEnabled;
  final bool attended;

  bool isPast(DateTime now) => startsAt.isBefore(now);
}

/// Resumo da semana (segunda a domingo).
class ActivitySummary {
  const ActivitySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.sessions,
    required this.minutes,
    required this.activeDays,
    required this.distanceKm,
    required this.weeklyGoal,
    required this.streakWeeks,
    required this.plans,
    required this.upcomingEvents,
    required this.recentSessions,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    final week = json['week'] as Map<String, dynamic>? ?? const {};
    return ActivitySummary(
      weekStart: DateTime.parse(week['start'] as String),
      weekEnd: DateTime.parse(week['end'] as String),
      sessions: toInt(week['sessions']) ?? 0,
      minutes: toInt(week['minutes']) ?? 0,
      activeDays: toInt(week['active_days']) ?? 0,
      distanceKm: toDouble(week['distance_km']) ?? 0,
      weeklyGoal: toInt(json['weekly_goal']) ?? 1,
      streakWeeks: toInt(json['streak_weeks']) ?? 0,
      plans: [
        for (final p in (json['plans'] as List<dynamic>? ?? const []))
          ActivityPlan.fromJson(p as Map<String, dynamic>),
      ],
      upcomingEvents: [
        for (final e in (json['upcoming_events'] as List<dynamic>? ?? const []))
          ActivityEvent.fromJson(e as Map<String, dynamic>),
      ],
      recentSessions: [
        for (final s in (json['recent_sessions'] as List<dynamic>? ?? const []))
          ActivitySession.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  final DateTime weekStart;
  final DateTime weekEnd;
  final int sessions;
  final int minutes;
  final int activeDays;
  final double distanceKm;

  /// Treinos por semana somando as metas (1 sem metas).
  final int weeklyGoal;
  final int streakWeeks;
  final List<ActivityPlan> plans;
  final List<ActivityEvent> upcomingEvents;
  final List<ActivitySession> recentSessions;

  double get weekProgress =>
      weeklyGoal <= 0 ? 0 : (sessions / weeklyGoal).clamp(0, 1).toDouble();
}
